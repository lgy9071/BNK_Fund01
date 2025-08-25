package com.example.fund.fund.repository_fund;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.fund.entity_fund.FundReview;

public interface FundReviewRepository extends JpaRepository<FundReview, Long> {

    @Query("""
        select r from FundReview r
        where r.fundId = :fundId and r.deletedAt is null
        order by r.createdAt desc
    """)
    Page<FundReview> findActiveByFundId(@Param("fundId") String fundId, Pageable pageable);

    @Query("""
        select count(r) from FundReview r
        where r.fundId = :fundId and r.deletedAt is null
    """)
    long countActiveByFundId(@Param("fundId") String fundId);

    @Query("""
        select r from FundReview r
        where r.fundId = :fundId and r.userId = :userId and r.deletedAt is null
    """)
    Optional<FundReview> findActiveByFundIdAndUserId(@Param("fundId") String fundId, @Param("userId") Integer userId);
}