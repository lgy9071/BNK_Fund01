package com.example.fund.account.repository;

import java.math.BigDecimal;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.account.entity.DepositAccount;

import jakarta.persistence.LockModeType;

public interface DepositAccountRepository extends JpaRepository<DepositAccount, Long>{
	// 존재 여부
	boolean existsByUser_UserId(Integer userId);
	
	// 사용자 ID로 엔티티 조회
	Optional<DepositAccount> findByUser_UserId(Integer userId);
	
	// 엔티티 조회 (쓰기 락) - 동시성 민감 구간에서 사용
	@Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from DepositAccount a where a.user.userId = :userId")
    Optional<DepositAccount> findByUserIdForUpdate(@Param("userId") Integer userId);
	
	// ID만 가져오기
    @Query("select a.accountId from DepositAccount a where a.user.userId = :userId")
    Optional<Long> findAccountIdByUserId(@Param("userId") Integer userId);
    

    // 잔액만 가져오기 (서비스에서 기본값 처리 권장)
    @Query("select a.balance from DepositAccount a where a.user.userId = :userId")
    Optional<BigDecimal> findBalanceByUserId(@Param("userId") Integer userId);
}
