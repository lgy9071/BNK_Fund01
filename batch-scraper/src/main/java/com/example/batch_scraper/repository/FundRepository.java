package com.example.batch_scraper.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.batch_scraper.entity.Fund;

/**
 * 1. Fund Repository - 기본 펀드 정보
 */
@Repository
public interface FundRepository extends JpaRepository<Fund, String> {
    
}