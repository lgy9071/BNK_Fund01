package com.example.fund.account.service;

import com.example.fund.account.dto.CreateDepositAccountRequestDto;
import com.example.fund.account.dto.CreateDepositAccountResponseDto;
import com.example.fund.account.dto.DepositAccountResponseDto;
import com.example.fund.account.entity.DepositAccount;
import com.example.fund.account.repository.DepositAccountRepository;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Random;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class DepositAccountService {

    private final DepositAccountRepository depositAccountRepository;
    private final UserRepository userRepository; // User 엔티티 조회용
    private final DepositTransactionService depositTransactionService;
    private final PasswordEncoder passwordEncoder; // BCrypt 암호화용

    /**
     * 입출금 계좌 생성
     */
    public CreateDepositAccountResponseDto createDepositAccount(CreateDepositAccountRequestDto requestDto) {
        // 1. 사용자 존재 여부 확인
        User user = userRepository.findById(requestDto.getUserId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

        // 2. 계좌번호 자동 생성
        String accountNumber = generateAccountNumber();

        // 3. 계좌 별칭 기본값 설정 (없으면 "사용자이름 입출금 계좌"로 설정)
        String accountName = requestDto.getAccountName();
        if (accountName == null || accountName.trim().isEmpty()) {
            accountName = user.getName() + " 입출금 계좌"; // User 엔티티에 getName() 있다고 가정
        }

        // 4. PIN 해시화
        String pinHash = passwordEncoder.encode(requestDto.getPin());

        // 5. DepositAccount 엔티티 생성
        DepositAccount depositAccount = DepositAccount.builder()
                .user(user)
                .accountNumber(accountNumber)
                .accountName(accountName)
                .pinHash(pinHash)
                .balance(BigDecimal.ZERO) // 기본 잔액 0
                .status(DepositAccount.AccountStatus.POSTED) // 기본 상태 POSTED
                .build();

        // 6. 저장
        DepositAccount savedAccount = depositAccountRepository.save(depositAccount);

        // 7. 계좌 생성 거래 이력 기록
        depositTransactionService.createAccountCreationTransaction(savedAccount);

        // 8. 응답 DTO 생성 및 반환
        return CreateDepositAccountResponseDto.builder()
                .accountId(savedAccount.getAccountId())
                .userId(savedAccount.getUser().getUserId())
                .accountNumber(savedAccount.getAccountNumber())
                .accountName(savedAccount.getAccountName())
                .balance(savedAccount.getBalance())
                .createdAt(savedAccount.getCreatedAt())
                .status(savedAccount.getStatus().name())
                .build();
    }

    /**
     * 사용자 ID로 계좌 목록 조회
     */
    @Transactional(readOnly = true)
    public List<DepositAccountResponseDto> getAccountsByUserId(Integer userId) {
        // 기존에 있던 findByUser_UserId()는 단일 계좌만 조회하므로
        // 여러 계좌 지원을 위해 새로 추가한 메서드 사용
        List<DepositAccount> accounts = depositAccountRepository.findByUserIdOrderByCreatedAtDesc(userId);

        return accounts.stream()
                .map(DepositAccountResponseDto::fromEntity)
                .collect(Collectors.toList());
    }

    /**
     * 계좌번호로 계좌 조회
     */
    @Transactional(readOnly = true)
    public DepositAccountResponseDto getAccountByAccountNumber(String accountNumber) {
        DepositAccount account = depositAccountRepository.findByAccountNumber(accountNumber)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 계좌번호입니다."));

        return DepositAccountResponseDto.fromEntity(account);
    }

    /**
     * 계좌번호 자동 생성 (3333-XX-XXXXXX 형식)
     */
    private String generateAccountNumber() {
        String bankCode = "3333"; // 은행 코드 고정

        int maxAttempts = 10;
        for (int attempt = 0; attempt < maxAttempts; attempt++) {
            // 중간 2자리 + 뒤 6자리 랜덤 생성
            String middle = String.format("%02d", new Random().nextInt(100));
            String suffix = String.format("%06d", new Random().nextInt(1000000));

            String accountNumber = bankCode + "-" + middle + "-" + suffix;

            // 중복 체크
            if (!depositAccountRepository.existsByAccountNumber(accountNumber)) {
                return accountNumber;
            }
        }

        throw new RuntimeException("계좌번호 생성에 실패했습니다. 다시 시도해주세요.");
    }
}

/*
기본 요청 (계좌명 지정)
json{
  "userId": 101,
  "accountName": "내 주계좌",
  "pin": "1234"
}

계좌명 미입력 (자동 설정)
json{
  "userId": 102,
  "pin": "5678"
}

최대 길이 계좌명
json{
  "userId": 103,
  "accountName": "김철수의 급여입금용 주거래 계좌입니다 정말 긴 이름이네요",
  "pin": "9999"
}


성공 응답 예제
json{
  "success": true,
  "data": {
    "accountId": 1,
    "userId": 101,
    "accountNumber": "3333-42-123456",
    "accountName": "내 주계좌",
    "balance": 0.00,
    "createdAt": "2025-08-23T14:30:15.123456",
    "status": "POSTED"
  },
  "message": "입출금 계좌가 성공적으로 생성되었습니다.",
  "errorCode": null,
  "pagination": null
}




*/


/*

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class DepositAccountService {

    private final DepositAccountRepository depositAccountRepository;
    private final UserRepository userRepository; // User 엔티티 조회용
    private final PasswordEncoder passwordEncoder; // BCrypt 암호화용

public CreateDepositAccountResponseDto createDepositAccount(CreateDepositAccountRequestDto requestDto) {
    // 1. 사용자 존재 여부 확인
    User user = userRepository.findById(requestDto.getUserId())
            .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));

    // 2. 계좌번호 자동 생성
    String accountNumber = generateAccountNumber();

    // 3. 계좌 별칭 기본값 설정 (없으면 "사용자이름 입출금 계좌"로 설정)
    String accountName = requestDto.getAccountName();
    if (accountName == null || accountName.trim().isEmpty()) {
        accountName = user.getName() + " 입출금 계좌"; // User 엔티티에 getName() 있다고 가정
    }

    // 4. PIN 해시화
    String pinHash = passwordEncoder.encode(requestDto.getPin());

    // 5. DepositAccount 엔티티 생성
    DepositAccount depositAccount = DepositAccount.builder()
            .user(user)
            .accountNumber(accountNumber)
            .accountName(accountName)
            .pinHash(pinHash)
            .balance(BigDecimal.ZERO) // 기본 잔액 0
            .status(DepositAccount.AccountStatus.POSTED) // 기본 상태 POSTED
            .build();

    // 6. 저장
    DepositAccount savedAccount = depositAccountRepository.save(depositAccount);

    log.info("입출금 계좌가 생성되었습니다. 사용자ID: {}, 계좌번호: {}",
            user.getUserId(), savedAccount.getAccountNumber());

    // 7. 응답 DTO 생성 및 반환
    return CreateDepositAccountResponseDto.builder()
            .accountId(savedAccount.getAccountId())
            .userId(savedAccount.getUser().getUserId())
            .accountNumber(savedAccount.getAccountNumber())
            .accountName(savedAccount.getAccountName())
            .balance(savedAccount.getBalance())
            .createdAt(savedAccount.getCreatedAt())
            .status(savedAccount.getStatus().name())
            .build();
}

@Transactional(readOnly = true)
public List<DepositAccountResponseDto> getAccountsByUserId(Integer userId) {
    // 기존에 있던 findByUser_UserId()는 단일 계좌만 조회하므로
    // 여러 계좌 지원을 위해 새로 추가한 메서드 사용
    List<DepositAccount> accounts = depositAccountRepository.findByUserIdOrderByCreatedAtDesc(userId);

    return accounts.stream()
            .map(DepositAccountResponseDto::fromEntity)
            .collect(Collectors.toList());
}

@Transactional(readOnly = true)
public DepositAccountResponseDto getAccountByAccountNumber(String accountNumber) {
    DepositAccount account = depositAccountRepository.findByAccountNumber(accountNumber)
            .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 계좌번호입니다."));

    return DepositAccountResponseDto.fromEntity(account);
}

private String generateAccountNumber() {
    String bankCode = "3333"; // 은행 코드 고정

    int maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
        // 중간 2자리 + 뒤 6자리 랜덤 생성
        String middle = String.format("%02d", new Random().nextInt(100));
        String suffix = String.format("%06d", new Random().nextInt(1000000));

        String accountNumber = bankCode + "-" + middle + "-" + suffix;

        // 중복 체크
        if (!depositAccountRepository.existsByAccountNumber(accountNumber)) {
            return accountNumber;
        }
    }

    throw new RuntimeException("계좌번호 생성에 실패했습니다. 다시 시도해주세요.");
}
}

 */