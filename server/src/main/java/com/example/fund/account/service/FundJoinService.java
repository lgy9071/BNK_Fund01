package com.example.fund.account.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Optional;
import java.util.UUID;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.example.fund.account.entity.Branch;
import com.example.fund.account.entity.DepositAccount;
import com.example.fund.account.entity.DepositTransaction;
import com.example.fund.account.entity.FundAccount;
import com.example.fund.account.entity.FundAccountTransaction;
import com.example.fund.account.entity.FundTransaction;
import com.example.fund.account.entity.TransitAccount;
import com.example.fund.account.entity.TransitTransaction;
import com.example.fund.account.repository.DepositAccountRepository;
import com.example.fund.account.repository.DepositTransactionRepository;
import com.example.fund.account.repository.FundAccountRepository;
import com.example.fund.account.repository.FundAccountTransactionRepository;
import com.example.fund.account.repository.FundTransactionRepository;
import com.example.fund.account.repository.TransitAccountRepository;
import com.example.fund.account.repository.TransitTransactionRepository;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundProduct;
import com.example.fund.fund.repository_fund.FundFeeInfoRepository;
import com.example.fund.fund.repository_fund.FundStatusDailyRepository;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;
import com.example.fund.holiday.HolidayService;
import com.example.fund.user.entity.User;

import jakarta.transaction.Transactional;
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
	
	private final HolidayService holidayService;

	private final BCryptPasswordEncoder passwordEncoder;
	
	// ---- 설정 상수 ----
    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
	
	
	 // ---- 1) 가입 조건 조회 ----
	public void checkJoin(User user) {
		checkDepositAccount(user.getUserId()); // T/F
		checkInvestProfile(user.getUserId());  // T/F
	}
	
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
	
	// ---- 2) 펀드가입 오케스트레이션(원자성 보장) ----
	@Transactional(rollbackOn = Exception.class)
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
				.orElseThrow(()-> new IllegalStateException("Deposit Account Not Fount"));
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
	@Transactional(rollbackOn = Exception.class)
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
	public void createFundTransaction(User user,
									  DepositAccount depositAccount,
									  FundProduct fundProduct,
									  FundAccount fundAccount,
									  BigDecimal orderAmount,
									  Branch branch,
									  FundTransaction.InvestRuleType ruleType,
									  String ruleValue) {// 규칙값(요일/일자 등)
		Fund fund = fundProduct.getFund();
		String fundId = fund.getFundId();
		
		 ZonedDateTime now = ZonedDateTime.now(KST);
	     LocalDate D = now.toLocalDate(); // 주문일
		
		// 컷오프 시간
	    LocalTime cutoff = switch (fund.getFundType()) {
         case "주식형" -> LocalTime.of(15, 30);
         case "채권형" -> LocalTime.of(17, 0);
         default       -> LocalTime.of(17, 0);
    	};
    	
    	// 컷오프 기준 NAV 적용일(T): now < cutoff ? D : D+1
        LocalDate T = now.toLocalTime().isBefore(cutoff) ? D : D.plusDays(1);
        
        // NAV 적용일(navDate) = T를 영업일로 보정
        LocalDate navDate = holidayService.normalizeToBusinessDay(T);

		// 기준가
		BigDecimal navPrice = fundStatusDailyRepo
					    .findNavPriceByFundIdAndBaseDate(fundId, navDate)
					    .orElseThrow(() -> new IllegalStateException("NAV not found for fundId=" + fundId))
					    .setScale(2, RoundingMode.HALF_UP);
		if (navPrice.signum() <= 0) {
	        throw new IllegalStateException("Invalid NAV price: " + navPrice);
	    }
		
		// 선취수수료 (null → 0, 퍼센트표기 방어)
        BigDecimal frontLoadFee = Optional.ofNullable(fundFeeInfoRepo.findFrontLoadFeeByFundId(fund.getFundId()))
            .orElse(BigDecimal.ZERO);
        if (frontLoadFee.compareTo(BigDecimal.ONE) > 0) {
            // % 단위로 저장된 경우 환산
            if (frontLoadFee.compareTo(new BigDecimal("100")) > 0) {
                throw new IllegalStateException("Invalid frontLoadFee: " + frontLoadFee);
            }
            frontLoadFee = frontLoadFee.movePointLeft(2);
        }
        
		// 실제 투자금액
		BigDecimal investAmount = orderAmount
								  .multiply(BigDecimal.ONE.subtract(frontLoadFee))
								  .setScale(0, RoundingMode.DOWN); // 원 단위로 절사
		// 좌수
		BigDecimal units = investAmount.divide(navPrice, 0, RoundingMode.DOWN);  // 소수점 버림
		
		// now: ZonedDateTime, D: 주문일(LocalDate), cutoff: LocalTime
		LocalDate base = now.toLocalTime().isBefore(cutoff)
		        ? D.plusDays(1)   // 컷오프 이전 → T+1
		        : D.plusDays(2);  // 컷오프 이후 → T+2
		

		// 정산일
		int settleLag = switch (fund.getFundType()) {
		    case "주식형" -> 3; // T+3 영업일
		    case "채권형" -> 2; // T+2 영업일
		    default -> 3;
		};
		
		LocalDate settlementDate = T;
		for (int i = 0; i < settleLag; i++) {
		    settlementDate = holidayService.nextBusinessDay(settlementDate); // 다음 영업일로 1칸
		}

		// 주말/공휴일 제외한 실제 매수확정일
		LocalDate executionDate = holidayService.nextBusinessDay(base);
		
		FundTransaction fundTx = FundTransaction.builder()
												.fund(fundProduct)
												.fundAccount(fundAccount)
												.user(user)
												.type(FundTransaction.TransactionType.PURCHASE)
												.amount(investAmount)
												.unitPrice(navPrice) // 기준가(거래일 기준) - FundStatusDaily : nav_price
												.units(units) // 좌수 (거래금액 / 기준가)
												.branch(branch) //사후관리지점
												.depositAccount(depositAccount) // 입출금 계좌
												.investRule(ruleType)        // 투자 규칙 (Enum)
									            .investRuleValue(ruleValue)  // 요일 or 일자 값
												.requestedAt(now.toLocalDateTime()) // 접수시각
												.tradeDate(D) // 거래일 (컷오프기준)
												.navDate(T) // 기준가 적용일
												.processedAt(executionDate) // 매수확정일(체결일)
												.settlementDate(T)
				        						.build();
	fundTransactionRepo.save(fundTx);
	}

	// 5) 매수일에 대기 -> 펀드 로 잔액 이동
	@Transactional(rollbackOn = Exception.class)
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
	
	
	// 임시저장
	
	// 사후 관리지점
	public Branch managingBranch() {
		Branch branch = null;
		return branch;
	}
}
