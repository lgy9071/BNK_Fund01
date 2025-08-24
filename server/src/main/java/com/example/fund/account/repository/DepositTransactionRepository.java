package com.example.fund.account.repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.DepositTransaction;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface DepositTransactionRepository extends JpaRepository<DepositTransaction, Long> {
    //	Optional<DepositTransaction> findByDepositAccount_AccountId(Long AccountId);

    // =======

    /**
     * 계좌 ID로 거래 이력 조회 (생성일 내림차순)
     */
    @Query("SELECT dt FROM DepositTransaction dt WHERE dt.account.accountId = :accountId ORDER BY dt.createdAt DESC")
    List<DepositTransaction> findByAccountIdOrderByCreatedAtDesc(@Param("accountId") Long accountId);

    /**
     * 거래 상태별 조회
     */
    List<DepositTransaction> findByStatusOrderByCreatedAtDesc(String status);

    /**
     * 특정 기간 거래 이력 조회
     */
    @Query("SELECT dt FROM DepositTransaction dt WHERE dt.account.accountId = :accountId " +
            "AND dt.createdAt BETWEEN :startDate AND :endDate ORDER BY dt.createdAt DESC")
    List<DepositTransaction> findByAccountIdAndDateRange(
            @Param("accountId") Long accountId,
            @Param("startDate") LocalDateTime startDate,
            @Param("endDate") LocalDateTime endDate);

    /**
     * Transfer ID로 관련 거래들 조회
     */
    List<DepositTransaction> findByTransferId(String transferId);
}