package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.FundProduct;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface FundProductRepository extends JpaRepository<FundProduct, Long> {
    Optional<FundProduct> findTopByFund_FundIdOrderByProductIdDesc(String fundId);
    
    // fund_id로 상품 조회
    FundProduct findByFund_FundId(String fundId);
}