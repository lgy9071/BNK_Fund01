package com.example.fund.fund.repository_fund;

import com.example.batch_scraper.entity.Fund;
import com.example.batch_scraper.entity.FundPriceDaily;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;

@Repository
public interface FundPriceDailyRepository extends JpaRepository<FundPriceDaily, Long> { 

	boolean existsByFundAndBaseDate(Fund fund, LocalDate baseDate);
}