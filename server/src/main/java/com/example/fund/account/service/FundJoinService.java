package com.example.fund.account.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.account.entity.Branch;
import com.example.fund.account.entity.DepositAccount;
import com.example.fund.account.entity.DepositTransaction;
import com.example.fund.account.entity.FundAccount;
import com.example.fund.account.entity.FundAccountTransaction;
import com.example.fund.account.entity.FundTransaction;
import com.example.fund.account.entity.TermsAgreement;
import com.example.fund.account.entity.TransitAccount;
import com.example.fund.account.entity.TransitTransaction;
import com.example.fund.account.repository.BranchRepository;
import com.example.fund.account.repository.DepositAccountRepository;
import com.example.fund.account.repository.DepositTransactionRepository;
import com.example.fund.account.repository.FundAccountRepository;
import com.example.fund.account.repository.FundAccountTransactionRepository;
import com.example.fund.account.repository.FundTransactionRepository;
import com.example.fund.account.repository.TermsAgreementRepository;
import com.example.fund.account.repository.TransitAccountRepository;
import com.example.fund.account.repository.TransitTransactionRepository;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundProduct;
import com.example.fund.fund.repository_fund.FundFeeInfoRepository;
import com.example.fund.fund.repository_fund.FundProductRepository;
import com.example.fund.fund.repository_fund.FundStatusDailyRepository;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;
import com.example.fund.holiday.HolidayService;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;

import lombok.RequiredArgsConstructor;


@Service
@RequiredArgsConstructor
public class FundJoinService {
	
	private final DepositAccountRepository depositAccountRepo;
	private final InvestProfileResultRepository investProfileResultRepo;
	private final FundAccountRepository fundAccountRepo;
	private final DepositTransactionRepository depositTransactionRepo;
	private final FundTransactionRepository fundTransactionRepo;
	private final TransitAccountRepository transitAccountRepo;
	private final TransitTransactionRepository transitTransactionRepo;
	private final FundStatusDailyRepository fundStatusDailyRepo;
	private final FundFeeInfoRepository fundFeeInfoRepo;
	private final FundAccountTransactionRepository fundAccountTransactionRepo;
	private final UserRepository userRepository;
	private final FundProductRepository fundProductRepository;
	private final BranchRepository branchRepository;
	private final TermsAgreementRepository termsAgreementRepo;
	
	private final HolidayService holidayService;

	private final BCryptPasswordEncoder passwordEncoder;
	
	// ---- 설정 상수 ----
    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
	
	
	// 입출금계좌 여부 확인
		public boolean checkDepositAccount(Integer userId) {
			return depositAccountRepo.existsByUser_UserId(userId);
		}
		
	// 투자성향분석 여부 확인 -- 분석X or 1년 만료
		public boolean checkInvestProfile(Integer userId) {
			Optional<LocalDateTime> result = investProfileResultRepo.findAnalysisDateByUserId(userId);
			boolean check = true;
			if(result.isEmpty()) return false;
			LocalDateTime analysisDate = result.get();
			return analysisDate.plusYears(1).isAfter(LocalDateTime.now());
		}
		
		
		// FundJoinService.java (필드/임포트는 아래 2) 참고)
		@Transactional(rollbackFor = Exception.class)
		public void fundJoin(Integer uid, String fundId, Long amount, String rawPin,
		                     String branchName, String ruleType, String ruleValue) {

		  if (uid == null) throw new IllegalArgumentException("uid is required");
		  if (fundId == null || fundId.isBlank()) throw new IllegalArgumentException("fundId is required");
		  if (amount == null || amount <= 0) throw new IllegalArgumentException("amount must be > 0");
		  if (rawPin == null || !rawPin.matches("\\d{4}")) throw new IllegalArgumentException("rawPin must be 4 digits");
		  if (ruleType == null || ruleType.isBlank()) throw new IllegalArgumentException("ruleType is required");

		  User user = userRepository.findById(uid)
		      .orElseThrow(() -> new IllegalArgumentException("User not found"));
		  FundProduct fund = fundProductRepository.findTopByFund_FundIdOrderByProductIdDesc(fundId)
		      .orElseThrow(() -> new IllegalArgumentException("FundProduct not found"));

		  Branch branch = null;
		  if (branchName != null && !branchName.isBlank()) {
		    branch = branchRepository.findByBranchName(branchName).orElse(null);
		  }

		  FundTransaction.InvestRuleType type = FundTransaction.InvestRuleType.valueOf(ruleType);

		  BigDecimal orderAmount = BigDecimal.valueOf(amount).setScale(0, RoundingMode.UNNECESSARY);

		  // ✅ 기존 메서드 재사용 (네가 올린 fundJoin(User, FundProduct, ...) 그대로 사용)
		  fundJoin(user, fund, orderAmount, rawPin, branch, type, (ruleValue == null ? "" : ruleValue));
		}

	// ---- 2) 펀드가입 오케스트레이션(원자성 보장) ----
	public void fundJoin(User user, FundProduct fund, BigDecimal orderAmount, String rawPin, Branch branch,
						 FundTransaction.InvestRuleType ruleType, String ruleValue) {
		if (user == null || user.getUserId() == null) {
            throw new IllegalArgumentException("user is required");
        }
        if (!checkDepositAccount(user.getUserId())) {
            throw new IllegalStateException("입출금 계좌가 없습니다.");
        }
        if (!checkInvestProfile(user.getUserId())) {
            throw new IllegalStateException("투자성향분석이 없거나 1년이 경과했습니다.");
        }
        
        // 2-1) 펀드 계좌 생성(없으면 생성)
		FundAccount fundAccount = createFundAccount(user, fund, rawPin);
		
		// 2-2) 입출금 -> 대기 이동(금액 홀딩)
		accountTransaction(user, orderAmount);
		
		// 2-3) 펀드 거래 생성/저장
		DepositAccount depositAccount = depositAccountRepo.findByUser_UserId(user.getUserId())
				.orElseThrow(()-> new IllegalStateException("Deposit Account Not Found"));
		createFundTransaction(user, depositAccount, fund, fundAccount, orderAmount, branch, ruleType, ruleValue);
	}
	
	// ---- 3) 펀드 계좌 생성 ----
	// Service 내부에 보관 (스레드 안전한 SecureRandom 재사용 권장)
	private static final SecureRandom RND = new SecureRandom();
	
	   public FundAccount createFundAccount(User user, FundProduct fund, String rawPin) {
	      if(user == null || user.getUserId() == null) throw new IllegalArgumentException("userId가 필요합니다.");
	      if(fund == null || fund.getProductId() == null) throw new IllegalArgumentException("productId가 필요합니다.");
	      if(rawPin == null || rawPin.isBlank()) throw new IllegalArgumentException("PIN이 필요합니다.");
	      
	      // 이미 존재하면 재사용 (없으면 생성)
	      Optional<FundAccount> existing = fundAccountRepo.findByUser_UserIdAndFundProduct_ProductId(user.getUserId(), fund.getProductId());
	      if(existing.isPresent()) {
	    	  return existing.get();
	      }
	      
	      // 계좌번호 생성
	      String accountNumber = generateUniqueAccountNumber();
	      
	      // PIN 해
	      String pinHash = passwordEncoder.encode(rawPin);
	      
	      FundAccount fundAccount = FundAccount.builder()
	                                 .user(user)
	                                 .fundProduct(fund)
	                                 .fundAccountNumber(accountNumber)
	                                 .fundPinHash(pinHash)
	                                 .units(BigDecimal.ZERO.setScale(4))
	                                 .lockedUnits(BigDecimal.ZERO.setScale(4))
	                                 .availableAmount(BigDecimal.ZERO.setScale(0))
	                                 .totalInvested(BigDecimal.ZERO.setScale(0))
	                                 .avgUnitPrice(BigDecimal.ZERO.setScale(2))
	                                 .fundValuation(BigDecimal.ZERO.setScale(2))
	                                 .status(FundAccount.FundAccountStatus.NORMAL)
	                                 .build();
	      
	      return fundAccountRepo.save(fundAccount);
	   }
	   
	   private String generateUniqueAccountNumber() {
	      while(true) {
	         String candidate = newAccountNumber();
	         if(!fundAccountRepo.existsByFundAccountNumber(candidate)) {
	            return candidate;
	         }
	      }
	   }


	/* 포맷: 125XXXXXXXXXXYY (하이픈 없는 버전) */
	private String newAccountNumber() {
	    int part1 = RND.nextInt(10000);
	    int part2 = RND.nextInt(10000);
	    String raw = String.format("125%04d%04d", part1, part2); // 125 + 8자리
	    int checksum = mod97(raw);
	    return String.format("125%04d%04d%02d", part1, part2, checksum); // 최종 13자리
	}

	// 체크섬 규칙: "125 + 8자리 난수"를 mod 97로 계산한 결과 (00~96) → 2자리 표시
	private int mod97(String digits) {
	    int rem = 0;
	    for (int i = 0; i < digits.length(); i++) {
	        rem = (rem * 10 + (digits.charAt(i) - '0')) % 97;
	    }
	    return rem;
	}
	// 히히
	// 체크섬 검증
	private boolean verifyAccountNumber(String formatted) {
	    // 유효성 검사 (하이픈 없는 13자리 숫자)
	    if (formatted == null || !formatted.matches("^125\\d{10}$")) {
	        return false;
	    }
	    try {
	        String raw = formatted.substring(0, 11);  // 앞의 11자리 (체크섬 제외)
	        int checksum = Integer.parseInt(formatted.substring(11)); // 마지막 2자리 체크섬
	        return mod97(raw) == checksum;
	    } catch (NumberFormatException | IndexOutOfBoundsException e) {
	        return false;
	    }
	}

	
	// ---- 4) 입출금 -> 대기: 금액 홀딩 & 거래 내역 적재 ----
	// 입출금 거래 내역 & 대기계좌내역 생성
	@Transactional(rollbackFor = Exception.class)
	public void accountTransaction(User user, BigDecimal orderAmount) {

		 if(orderAmount == null || orderAmount.signum() <= 0) {
			 throw new IllegalArgumentException("orderAmount must be > 0");
		 }
		 /// 원 단위 고정(소수 입력 차단)
		 orderAmount = orderAmount.setScale(0, RoundingMode.UNNECESSARY);  // scale 고정
		
		 // 잠금 걸고 조회
		 DepositAccount depositAccount =depositAccountRepo
				 .findByUserIdForUpdate(user.getUserId())
				 .orElseThrow(() -> new IllegalStateException("Deposit account not found"));		 
		 TransitAccount transitAccount = transitAccountRepo
				 .findByIdForUpdate(1)
				 .orElseThrow(() -> new IllegalStateException("Transit account not found"));

		 
		// 잔액 검증
		 BigDecimal currentBalance = depositAccount.getBalance(); // 입출금 계좌 현재 잔액
		 if(currentBalance.compareTo(orderAmount) < 0) {
			 throw new IllegalArgumentException("Insufficient balance");
		 }
		 BigDecimal transitBalance = transitAccount.getBalance(); // 대기계좌 현재 잔액
		 // 잔액 변경
		depositAccount.setBalance(currentBalance.subtract(orderAmount));
		transitAccount.setBalance(transitBalance.add(orderAmount));
		
		// 거래내역 적재 (공통 transferId로 체인 추적)
		String transferId = UUID.randomUUID().toString();
			 
		// 거래내역 저장
		DepositTransaction depositTx = DepositTransaction.builder()
														 .account(depositAccount)
														 .amount(orderAmount)
														 .txType(DepositTransaction.TxType.WITHDRAW)
														 .transferId(transferId)
														 .counterparty(transitAccount.getTransitAccountNumber())
														 .build();
		depositTransactionRepo.save(depositTx);

		TransitTransaction transitTx = TransitTransaction.builder()
														 .transitAccountId(transitAccount.getTransitAccountId())
											 			 .counterparty(depositAccount.getAccountNumber()) // 상대 계좌번호
											 		     .txType(TransitTransaction.TxType.DEPOSIT)
											 			 .amount(orderAmount)
											 			 .transferId(transferId)
											 			 .build();
		transitTransactionRepo.save(transitTx);	 
	 }
	
	// 4) 펀드거래내역 생성
	// ───────────────── helper ─────────────────
	private enum FundKind { EQUITY, BOND, OTHER }

	private FundKind classifyFundKind(String t) {
	    if (t == null) return FundKind.OTHER;
	    t = t.trim();
	    if (t.equals("주식형") || t.equals("주식혼합형")) return FundKind.EQUITY;
	    if (t.equals("채권형") || t.equals("채권혼합형")) return FundKind.BOND;
	    return FundKind.OTHER;
	}

	private LocalTime cutoffOf(FundKind kind) {
	    return switch (kind) {
	        case EQUITY -> LocalTime.of(15, 30);
	        case BOND, OTHER -> LocalTime.of(17, 0);
	    };
	}

	private int executionLagBD(FundKind kind) { // 체결 래그
	    return switch (kind) {
	        case EQUITY -> 1; // 주식/주식혼합: T+1BD
	        case BOND   -> 2; // 채권/채권혼합: T+2BD
	        default     -> 1;
	    };
	}

	private int settlementLagBD(FundKind kind) { // 정산 래그
	    return switch (kind) {
	        case EQUITY -> 3; // 주식: T+3BD
	        case BOND   -> 2; // 채권: T+2BD
	        default     -> 3;
	    };
	}

	// ───────────────── 여기부터 교체 ─────────────────
	public FundTransaction createFundTransaction(User user,
	                                  DepositAccount depositAccount,
	                                  FundProduct fundProduct,
	                                  FundAccount fundAccount,
	                                  BigDecimal orderAmount,
	                                  Branch branch,
	                                  FundTransaction.InvestRuleType ruleType,
	                                  String ruleValue) {

	    Fund fund = fundProduct.getFund();

	    // 현재시각 및 유형/컷오프
	    ZonedDateTime now = ZonedDateTime.now(KST);           // 고객 실제 제출 타임스탬프
	    FundKind kind = classifyFundKind(fund.getFundType());
	    LocalTime cutoff = cutoffOf(kind);
	    LocalTime businessOpen = LocalTime.of(9, 0);

	    // 주문일(D) = 고객이 버튼 누른 달력상의 날짜 (보정 없음)
	    LocalDate D = now.toLocalDate();

	    // 신청일/기준가일(T) = 업무일/컷오프 보정된 접수시각의 '날짜'
	    ZonedDateTime acceptedAt = normalizeToBusinessOpen(now, businessOpen, cutoff, holidayService);
	    LocalDate T = acceptedAt.toLocalDate();
	    LocalDate navDate = T;

	    // 체결일(매수확정) = T + (유형별)영업일
	    LocalDate processedAt = holidayService.addBusinessDays(T, executionLagBD(kind));

	    // 정산일 = T + (유형별)영업일 (주식 T+3, 채권 T+2)
	    LocalDate settlementDate = holidayService.addBusinessDays(T, settlementLagBD(kind));

	    // 이 단계에선 NAV/좌수 확정하지 않음 (마감 후 배치에서 확정)
	    FundTransaction fundTx = FundTransaction.builder()
	        .fund(fundProduct)
	        .fundAccount(fundAccount)
	        .user(user)
	        .type(FundTransaction.TransactionType.PURCHASE)
	        .amount(orderAmount)                  // 주문 총액(수수료/실투자액은 배치에서 계산 권장)
	        .unitPrice(null)                      // ← 배치에서 T일 NAV 확정 후 세팅
	        .units(null)                          // ← 배치에서 확정
	        .branch(branch)
	        .depositAccount(depositAccount)
	        .investRule(ruleType)
	        .investRuleValue(ruleValue)
	        .requestedAt(now.toLocalDateTime())   // 고객 제출 실제 시각(로그/감사용)
	        .tradeDate(D)                         // 주문일(고객 관점)
	        .navDate(navDate)                     // 기준가 적용일(= T)
	        .processedAt(processedAt)             // 체결일(매수확정일)
	        .settlementDate(settlementDate)       // 정산일
	        .build();

	    return fundTransactionRepo.save(fundTx);
	}





	// 5) 매수일에 대기 -> 펀드 로 잔액 이동
	@Transactional(rollbackFor = Exception.class)
	public void settleToFund(User user,
	                         FundAccount fundAccount,
	                         TransitAccount transitAccount,
	                         BigDecimal orderAmount,
	                         BigDecimal navPrice,
	                         FundTransaction fundTransaction) {
		
		// 금액/좌수 계산 (원단위 절사 일관)
	    BigDecimal investAmount = orderAmount.setScale(0, RoundingMode.DOWN);
	    BigDecimal units = investAmount.divide(navPrice, 3, RoundingMode.DOWN);
	    
	    // 1) 대기계좌 잔액 차감
	    if (transitAccount.getBalance().compareTo(investAmount) < 0) {
	        throw new IllegalStateException("대기계좌 잔액 부족");
	    }
	    transitAccount.setBalance(transitAccount.getBalance().subtract(investAmount));

	    // 2) 펀드계좌 잔액 증가 (좌수 기준)
	    fundAccount.setAvailableAmount(fundAccount.getAvailableAmount().add(investAmount));
	    fundAccount.setUnits(fundAccount.getUnits().add(units));
	    
	    
	    String transferId = UUID.randomUUID().toString();
	    
	    // 2-1) 거래내역: 대기(WITHDRAW), 펀드(DEPOSIT)
	    TransitTransaction transitTx = TransitTransaction.builder()
	    		.transitAccountId(transitAccount.getTransitAccountId())
	            .txType(TransitTransaction.TxType.WITHDRAW)
	            .amount(investAmount)
	            .counterparty(fundAccount.getFundAccountNumber()) // 또는 fundAccount.getFundAccountId().toString()
	            .transferId(transferId)
	            .build();

	    FundAccountTransaction fundAccTx = FundAccountTransaction.builder()
	            .fundAccount(fundAccount)
	            .txType(FundAccountTransaction.TxType.DEPOSIT)
	            .amount(investAmount)
	            .counterparty(transitAccount.getTransitAccountNumber()) // 또는 transitAccount.getTransitAccountNumber()
	            .transferId(transferId)
	            .build();

	    // 3) 저장
	    transitAccountRepo.save(transitAccount);
	    fundAccountRepo.save(fundAccount);
	    transitTransactionRepo.save(transitTx);
	    fundAccountTransactionRepo.save(fundAccTx);
	}
	
	// 계좌 번호 조회
	public String getAccountNumber(Integer userId) {
        return depositAccountRepo.findAccountNumberByUserId(userId);
    }
	
	// 영업시간 정규화: 제출 시각(now)을 "실제 접수 가능한 영업일 09:00"로 보정
	private ZonedDateTime normalizeToBusinessOpen(ZonedDateTime nowKst,
	                                              LocalTime businessOpen,     // 09:00
	                                              LocalTime cutOff,           // 펀드별 컷오프
	                                              HolidayService holidaySvc) {
	    LocalDate d = nowKst.toLocalDate();
	    // 1) 휴일이면 다음 영업일 09:00
	    if (!holidaySvc.isBusinessDay(d)) {
	        LocalDate nd = holidaySvc.nextBusinessDay(d);
	        return ZonedDateTime.of(nd, businessOpen, nowKst.getZone());
	    }

	    LocalTime t = nowKst.toLocalTime();

	    // 2) 영업개시 전(00:00~09:00) -> 당일 09:00
	    if (t.isBefore(businessOpen)) {
	        return ZonedDateTime.of(d, businessOpen, nowKst.getZone());
	    }

	    // 3) 영업시간(09:00~컷오프) -> 그대로 유지
	    if (!t.isAfter(cutOff)) {
	        return nowKst;
	    }

	    // 4) 컷오프 이후(컷오프~24:00) -> 다음 영업일 09:00
	    LocalDate nd = holidaySvc.nextBusinessDay(d);
	    return ZonedDateTime.of(nd, businessOpen, nowKst.getZone());
	}
	
	@Transactional(rollbackFor = Exception.class)
	public Long fundJoinAndReturnTxId(Integer uid, String fundId, Long amount, String rawPin,
	                                  String branchName, String ruleType, String ruleValue) {
	    // 기존 fundJoin(...) 전처리와 동일
	    User user = userRepository.findById(uid)
	        .orElseThrow(() -> new IllegalArgumentException("User not found"));
	    FundProduct fund = fundProductRepository
	        .findTopByFund_FundIdOrderByProductIdDesc(fundId)
	        .orElseThrow(() -> new IllegalArgumentException("FundProduct not found"));
	    Branch branch = (branchName == null || branchName.isBlank())
	        ? null : branchRepository.findByBranchName(branchName).orElse(null);

	    if (!checkDepositAccount(uid)) throw new IllegalStateException("입출금 계좌가 없습니다.");
	    if (!checkInvestProfile(uid))  throw new IllegalStateException("투자성향분석이 없거나 1년이 경과했습니다.");

	    FundAccount fundAccount = createFundAccount(user, fund, rawPin);
	    BigDecimal orderAmount = BigDecimal.valueOf(amount).setScale(0, RoundingMode.UNNECESSARY);
	    accountTransaction(user, orderAmount);

	    DepositAccount depositAccount = depositAccountRepo.findByUser_UserId(user.getUserId())
	        .orElseThrow(() -> new IllegalStateException("Deposit Account Not Found"));

	    // 🔑 트랜잭션 생성 시 PK를 바로 반환하도록 createFundTransaction을 Long 리턴으로 바꾸거나,
	    // 동일 로직의 반환 버전(createFundTransactionReturn) 추가
	    Long txId = createFundTransaction(
	        user, depositAccount, fund, fundAccount, orderAmount, branch,
	        FundTransaction.InvestRuleType.valueOf(ruleType), (ruleValue == null ? "" : ruleValue)
	    ).getOrderId();

	    return txId;
	}
	

	@Transactional(readOnly = true)
	public Map<String, Object> getJoinDates(Integer userId, Long transactionId) {
	    FundTransaction tx = fundTransactionRepo
	        .findByOrderIdAndUser_UserId(transactionId, userId)
	        .orElseThrow(() -> new IllegalArgumentException("거래를 찾을 수 없습니다."));
	
	    return Map.of(
	        "transactionId",  tx.getOrderId(),
	        "tradeDate",      tx.getTradeDate(),     // 투자신청일 (D)
	        "navDate",        tx.getNavDate(),       // 금액확정일 (T)
	        "processedAt",    tx.getProcessedAt(),   // 체결일
	        "settlementDate", tx.getSettlementDate() // 정산일
	    );
	}

	
	// 임시저장
	@Transactional
	public TermsAgreement createActiveAfterCompletion(Integer userId, Long productId) {
	    ZoneId KST = ZoneId.of("Asia/Seoul");
	    LocalDateTime now = LocalDateTime.now(KST);

	    // 오늘 이미 유효한 동의가 있으면 재생성 금지
	    Optional<TermsAgreement> todayActive = termsAgreementRepo
	        .findTopByUserIdAndProductIdAndIsActiveIsTrueAndExpiredAtAfterOrderByAgreedAtDesc(
	            userId, productId, now);

	    if (todayActive.isPresent()) {
	        return todayActive.get();
	    }

	    // 만료시각: 내일 00:00:00 (KST)
	    LocalDateTime nextMidnight = LocalDate.now(KST).plusDays(1).atStartOfDay();

	    return termsAgreementRepo.save(
	        TermsAgreement.builder()
	            .userId(userId)
	            .productId(productId)
	            .agreedAt(now)
	            .expiredAt(nextMidnight) // ✅ 다음날 00:00:00
	            .isActive(true)
	            .build()
	    );
	}

	
}
