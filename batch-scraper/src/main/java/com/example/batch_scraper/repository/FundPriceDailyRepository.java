package com.example.batch_scraper.repository;

import java.time.LocalDate;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.batch_scraper.entity.Fund;
import com.example.batch_scraper.entity.FundPriceDaily;

@Repository
public interface FundPriceDailyRepository extends JpaRepository<FundPriceDaily, Long> { 

	boolean existsByFundAndBaseDate(Fund fund, LocalDate baseDate);
}