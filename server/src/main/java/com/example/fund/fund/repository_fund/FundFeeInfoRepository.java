package com.example.fund.fund.repository_fund;

import java.math.BigDecimal;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundFeeInfo;

@Repository
public interface FundFeeInfoRepository extends JpaRepository<FundFeeInfo, Long> {
    void deleteByFund(Fund fund);
    
    // fund_id 기준으로 선취수수료 조회
    @Query("SELECT f.frontLoadFee FROM FundFeeInfo f WHERE f.fund.fundId = :fundId")
    BigDecimal findFrontLoadFeeByFundId(@Param("fundId") String fundId);
}
