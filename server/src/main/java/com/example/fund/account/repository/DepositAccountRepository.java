package com.example.fund.account.repository;

import java.math.BigDecimal;
import java.util.List;
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


    // ========== 계좌 생성을 위해 추가 필요한 메서드들 ==========
    /**
     * 계좌번호로 계좌 조회
     */
    Optional<DepositAccount> findByAccountNumber(String accountNumber);

    /**
     * 계좌번호 중복 체크 (계좌번호 생성 시 사용)
     */
    boolean existsByAccountNumber(String accountNumber);

    // ========== 추가로 유용한 메서드들 (선택사항) ==========
    /**
     * 사용자 ID로 계좌 목록 조회 (생성일 내림차순) - 여러 계좌 지원 시
     */
    @Query("SELECT da FROM DepositAccount da WHERE da.user.userId = :userId ORDER BY da.createdAt DESC")
    List<DepositAccount> findByUserIdOrderByCreatedAtDesc(@Param("userId") Integer userId);

    /**
     * 특정 상태의 계좌 목록 조회 - 관리자 기능용
     */
    List<DepositAccount> findByStatusOrderByCreatedAtDesc(DepositAccount.AccountStatus status);
}
