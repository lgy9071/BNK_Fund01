package com.example.fund.fund.repository_fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.fund.fund.entity_fund.FundProduct;

public interface FundProductRepository extends JpaRepository<FundProduct, Long> {
    
    Optional<FundProduct> findTopByFund_FundIdOrderByProductIdDesc(String fundId);
    
    // fund_id로 상품 조회
    FundProduct findByFund_FundId(String fundId);

    @Query("SELECT COUNT(fp) FROM FundProduct fp WHERE LOWER(fp.status) = 'published'")
    long countPublished();
}