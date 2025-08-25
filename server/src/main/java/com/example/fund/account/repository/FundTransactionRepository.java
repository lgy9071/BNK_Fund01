package com.example.fund.account.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.account.entity.FundTransaction;

public interface FundTransactionRepository extends JpaRepository<FundTransaction, Long> {
	
	Optional<FundTransaction> findByOrderIdAndUser_UserId(Long orderId, Integer userId);
	
	Optional<FundTransaction> findTopByUser_UserIdOrderByRequestedAtDesc(Integer userId);
	
	// 특정 거래 ID + 사용자 소유권 검증
    @Query("""
           select ft from FundTransaction ft
           where ft.orderId = :txId and ft.user.userId = :userId
           """)
    Optional<FundTransaction> findByOrderIdAndUserId(@Param("txId") Long txId,
                                                      @Param("userId") Integer userId);

    // 특정 펀드의 "가장 최근" 가입 거래 (requestedAt 내림차순)
    @Query("""
           select ft from FundTransaction ft
           where ft.user.userId = :userId
             and ft.type = com.example.fund.account.entity.FundTransaction$TransactionType.PURCHASE
             and ft.fund.fund.fundId = :fundId
           order by ft.requestedAt desc
           """)
    Optional<FundTransaction> findLatestPurchaseByUserAndFund(@Param("userId") Integer userId,
                                                              @Param("fundId") String fundId);
}
