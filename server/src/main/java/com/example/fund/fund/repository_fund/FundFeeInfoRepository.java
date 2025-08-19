package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundFeeInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FundFeeInfoRepository extends JpaRepository<FundFeeInfo, Long> {
    void deleteByFund(Fund fund);
}
