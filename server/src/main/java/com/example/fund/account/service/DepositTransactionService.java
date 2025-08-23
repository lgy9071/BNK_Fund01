package com.example.fund.account.service;

import com.example.fund.account.entity.DepositAccount;
import com.example.fund.account.entity.DepositTransaction;
import com.example.fund.account.repository.DepositTransactionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class DepositTransactionService {

    private final DepositTransactionRepository depositTransactionRepository;

    /**
     * 계좌 생성 거래 이력 생성
     */
    public void createAccountCreationTransaction(DepositAccount account) {
        String transferId = UUID.randomUUID().toString();

        DepositTransaction creationTransaction = DepositTransaction.builder()
                .account(account)
                .txType(DepositTransaction.TxType.DEPOSIT)
                .amount(BigDecimal.ZERO)
                .counterparty("SYSTEM")
                .status("POSTED")
                .transferId(transferId)
                .build();

        depositTransactionRepository.save(creationTransaction);

        log.info("계좌 생성 거래 이력 저장 완료 - 계좌ID: {}, 거래ID: {}",
                account.getAccountId(), transferId);
    }

    /**
     * 입금 거래 이력 생성
     */
    public void createDepositTransaction(DepositAccount account, BigDecimal amount, String counterparty) {
        validateDepositAmount(amount);

        String transferId = UUID.randomUUID().toString();

        DepositTransaction depositTransaction = DepositTransaction.builder()
                .account(account)
                .txType(DepositTransaction.TxType.DEPOSIT)
                .amount(amount)
                .counterparty(counterparty != null ? counterparty : "UNKNOWN")
                .status("POSTED")
                .transferId(transferId)
                .build();

        depositTransactionRepository.save(depositTransaction);

        log.info("입금 거래 이력 저장 완료 - 계좌번호: {}, 금액: {}",
                account.getAccountNumber(), amount);
    }

    /**
     * 출금 거래 이력 생성
     */
    public void createWithdrawTransaction(DepositAccount account, BigDecimal amount, String counterparty) {
        validateWithdrawAmount(account, amount);

        String transferId = UUID.randomUUID().toString();

        DepositTransaction withdrawTransaction = DepositTransaction.builder()
                .account(account)
                .txType(DepositTransaction.TxType.WITHDRAW)
                .amount(amount)
                .counterparty(counterparty != null ? counterparty : "UNKNOWN")
                .status("POSTED")
                .transferId(transferId)
                .build();

        depositTransactionRepository.save(withdrawTransaction);

        log.info("출금 거래 이력 저장 완료 - 계좌번호: {}, 금액: {}",
                account.getAccountNumber(), amount);
    }

    /**
     * 계좌별 거래 이력 조회
     */
    @Transactional(readOnly = true)
    public List<DepositTransaction> getTransactionHistory(Long accountId) {
        return depositTransactionRepository.findByAccountIdOrderByCreatedAtDesc(accountId);
    }

    /**
     * 입금 금액 유효성 검증
     */
    private void validateDepositAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("입금 금액은 0보다 커야 합니다.");
        }

        // 최대 입금 한도 검증 등 추가 가능
        BigDecimal maxDepositAmount = new BigDecimal("10000000"); // 1천만원
        if (amount.compareTo(maxDepositAmount) > 0) {
            throw new IllegalArgumentException("1회 최대 입금 한도를 초과했습니다.");
        }
    }

    /**
     * 출금 금액 유효성 검증
     */
    private void validateWithdrawAmount(DepositAccount account, BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("출금 금액은 0보다 커야 합니다.");
        }

        // 잔액 부족 검증
        if (account.getBalance().compareTo(amount) < 0) {
            throw new IllegalArgumentException("잔액이 부족합니다.");
        }
    }
}