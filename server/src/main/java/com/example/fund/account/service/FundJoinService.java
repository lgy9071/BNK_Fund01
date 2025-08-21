package com.example.fund.account.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.Optional;
import java.util.UUID;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.example.fund.account.entity.Branch;
import com.example.fund.account.entity.DepositAccount;
import com.example.fund.account.entity.DepositTransaction;
import com.example.fund.account.entity.FundAccount;
import com.example.fund.account.entity.FundTransaction;
import com.example.fund.account.entity.TransitAccount;
import com.example.fund.account.entity.TransitTransaction;
import com.example.fund.account.repository.DepositAccountRepository;
import com.example.fund.account.repository.DepositTransactionRepository;
import com.example.fund.account.repository.FundAccountRepository;
import com.example.fund.account.repository.FundTransactionRepository;
import com.example.fund.account.repository.TransitAccountRepository;
import com.example.fund.account.repository.TransitTransactionRepository;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundProduct;
import com.example.fund.fund.repository_fund.FundStatusDailyRepository;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;
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

	private final BCryptPasswordEncoder passwordEncoder;
	
	
	// 펀드가입 조건 조회
	public void checkJoin(User user) {
		checkDepositAccount(user.getUserId()); // T/F
		checkInvestProfile(user.getUserId());  // T/F
	}
	
	// 펀드가입
	public void fundJoin(User user, FundProduct fund, BigDecimal orderAmount, String rawPin, Branch branch) {
		createFundAccount(user, fund, rawPin); // 펀드 계좌 생성
		accountTransaction(user, orderAmount, fund); // 입출금 프로세스
		DepositAccount depositAccount = depositAccountRepo.findByUser_UserId(user.getUserId()).get();
		FundAccount fundAccount = fundAccountRepo.findByUser_UserId(user.getUserId()).get();
		createFundTransaction(user, depositAccount, fund, fundAccount, orderAmount, branch);
	}
	
	// 1) 입출금계좌 여부 확인 -- T/F
	public boolean checkDepositAccount(Integer userId) {
		boolean check = depositAccountRepo.existsByUser_UserId(userId);
		return check;
	}
	
	// 2) 투자성향분석 여부 확인 
	// - 분석 X or 1년 만료
	public boolean checkInvestProfile(Integer userId) {
		Optional<LocalDateTime> result = investProfileResultRepo.findAnalysisDateByUserId(userId);
		boolean check = true;
		if(result.isEmpty()) {
			// 분석이력X
			check = false;
		}else {
			LocalDateTime analysisDate = result.get();
			if(!analysisDate.plusYears(1).isAfter(LocalDateTime.now())) { // 1년 만료 시
				check = false;
			}
		}
		return check;
	}
	
	// 3) 펀드 계좌 생성 (잔액 : 0원)
	
	// Service 내부에 보관 (스레드 안전한 SecureRandom 재사용 권장)
	private static final SecureRandom RND = new SecureRandom();
	
	@Transactional
	   public FundAccount createFundAccount(User user, FundProduct fund, String rawPin) {
	      if(user == null || user.getUserId() == null) throw new IllegalArgumentException("userId가 필요합니다.");
	      if(fund == null || fund.getProductId() == null) throw new IllegalArgumentException("productId가 필요합니다.");
	      if(rawPin == null || rawPin.isBlank()) throw new IllegalArgumentException("PIN이 필요합니다.");
	      
	      // 계좌번호 생성
	      String accountNumber = generateUniqueAccountNumber();
	      
	      // 사용자가 입력한 비밀번호 → 암호화
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

	
	// 3) 입출금 -> 대기 : 대기계좌에 임시입금
	// 입출금 거래 내역 & 대기계좌내역 생성
	@Transactional(rollbackOn = Exception.class)
	public void accountTransaction(User user, BigDecimal orderAmount, FundProduct fund) {
		// --- 1) 파라미터 검증 ---
		 if(user == null || user.getUserId() == null) {
			 throw new IllegalArgumentException("user is required");
		 }
		 if(orderAmount == null || orderAmount.signum() <= 0) {
			 throw new IllegalArgumentException("orderAmount must be > 0");
		 }
		 orderAmount = orderAmount.setScale(0, RoundingMode.UNNECESSARY);  // scale 고정
		
		// --- 2) 계좌 조회 ---
		 DepositAccount depositAccount =depositAccountRepo
				 .findByUserIdForUpdate(user.getUserId())
				 .orElseThrow(() -> new IllegalStateException("Deposit account not found"));		 
		 TransitAccount transitAccount = transitAccountRepo
				 .findByIdForUpdate(1)
				 .orElseThrow(() -> new IllegalStateException("Transit account not found"));
		 FundAccount fundAccount = fundAccountRepo.findByUser_UserId(user.getUserId())
				 .orElseThrow(() -> new IllegalStateException("Fund account not found"));
		 
		// --- 3) 잔액 검증 ---
		 BigDecimal currentBalance = depositAccount.getBalance(); // 입출금 계좌 현재 잔액
		 if(currentBalance.compareTo(orderAmount) < 0) {
			 throw new IllegalArgumentException("Insufficient balance");
		 }
		 BigDecimal transitBalance = transitAccount.getBalance(); // 대기계좌 현재 잔액
		 
		 String transferId = UUID.randomUUID().toString();
		 // --- 4) 잔액 변경 ---
		depositAccount.setBalance(currentBalance.subtract(orderAmount));
		transitAccount.setBalance(transitBalance.add(orderAmount));
			 
		// --- 5) 거래내역 저장 ---
		DepositTransaction depositTx = DepositTransaction.builder()
														 .account(depositAccount)
														 .amount(orderAmount)
														 .txType(DepositTransaction.TxType.WITHDRAW)
														 .transferId(transferId)
														 .counterparty(transitAccount.getTransitAccountNumber())
														 .build();
		depositTransactionRepo.save(depositTx);

		TransitTransaction transitTx = TransitTransaction.builder()
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
									  Branch branch) {
		Fund fund = fundProduct.getFund();
		String fundId = fund.getFundId();
		
		
		// 거래일
		LocalDate T = LocalDate.now(ZoneId.of("Asia/Seoul"));
		// 컷오프 시간
		// 주식형 - 15:30, 채권형 - 17:00
		// 기준가 시간
		LocalTime cutoffTime;
		if ("주식형".equals(fund.getFundType())) {
		    cutoffTime = LocalTime.of(15, 30); 
		} else {
		    cutoffTime = LocalTime.of(17, 0); // 채권형 및 기타 기본값
		}
		
		if(LocalTime.now().isAfter(cutoffTime)) {
			T = T.plusDays(1);
		}
		
		// 기준가
		BigDecimal navPrice = fundStatusDailyRepo
					    .findNavPriceByFundIdAndBaseDate(fundId, T)
					    .orElseThrow(() -> new IllegalStateException("NAV not found for fundId=" + fundId));
				
		FundTransaction fundTx = FundTransaction.builder()
												.fund(fundProduct)
												.fundAccount(fundAccount)
												.user(user)
												.type(FundTransaction.TransactionType.PURCHASE)
												.amount(orderAmount)
												.unitPrice(navPrice) // 기준가(거래일 기준) - FundStatusDaily : nav_price
												.units(null) // 좌수 (거래금액 / 기준가)
												.branch(branch) //사후관리지점
												.depositAccount(depositAccount) // 입출금 계좌
												.investRule(null) // 투자 규칙
												.requestedAt(null) // 접수시각
												.tradeDate(null) // 거래일 (컷오프기준)
												.navDate(null) // 기준가 적용일
												.processedAt(null) // 정산일(실제 체결일)
				        						.build();
	}

	// 5) 매수일에 대기 -> 펀드 로 잔액 이동
	
	
	
	// 임시저장
	
	// 사후 관리지점

}
