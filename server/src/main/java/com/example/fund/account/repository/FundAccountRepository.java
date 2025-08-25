package com.example.fund.account.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.FundAccount;
import com.example.fund.fund.entity_fund.FundProduct;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FundAccountRepository extends JpaRepository<FundAccount, Long> {
	
	boolean existsByFundAccountNumber(String fundAccountNumber);
	
	Optional<FundAccount> findByUser_UserIdAndFundProduct_ProductId(Integer userId, Long productId);

	// 기본 조회 - 사용자의 활성 펀드 계좌 조회
	List<FundAccount> findByUser_UserIdAndStatus(
			Integer userId,
			FundAccount.FundAccountStatus status
	);

	// 페치 조인을 사용한 N+1 문제 해결
	@Query("""
        SELECT fa 
        FROM FundAccount fa 
        JOIN FETCH fa.fundProduct fp 
        JOIN FETCH fp.fund f 
        WHERE fa.user.userId = :userId 
          AND fa.status = :status
        ORDER BY fa.createdAt DESC
        """)
	List<FundAccount> findByUserIdWithFundInfo(
			@Param("userId") Integer userId,
			@Param("status") FundAccount.FundAccountStatus status
	);


	// 최신 기준가와 함께 조회 (더 정확한 평가액 계산용)
	@Query("""
        SELECT fa, fsd.navPrice
        FROM FundAccount fa 
        JOIN FETCH fa.fundProduct fp 
        JOIN FETCH fp.fund f 
        LEFT JOIN FundStatusDaily fsd ON f.fundId = fsd.fund.fundId
        WHERE fa.user.userId = :userId 
          AND fa.status = :status
          AND (fsd.baseDate = (
              SELECT MAX(fsd2.baseDate) 
              FROM FundStatusDaily fsd2 
              WHERE fsd2.fund.fundId = f.fundId
          ) OR fsd.baseDate IS NULL)
        ORDER BY fa.createdAt DESC
        """)
	List<Object[]> findByUserIdWithLatestNavPrice(
			@Param("userId") Integer userId,
			@Param("status") FundAccount.FundAccountStatus status
	);
}
