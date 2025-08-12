package com.example.ap.repository.fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.common.entity.fund.FundPortfolio;

@Repository
public interface FundPortfolioRepository extends JpaRepository<FundPortfolio, Long> {

    /**
     * 펀드 ID로 포트폴리오 정보 조회
     * @param fundId 펀드 ID
     * @return 펀드 포트폴리오 정보
     */
    @Query("SELECT fp FROM FundPortfolio fp WHERE fp.fund.fundId = :fundId")
    Optional<FundPortfolio> findByFundId(@Param("fundId") Long fundId);

    /**
     * 펀드 ID로 포트폴리오 존재 여부 확인
     * @param fundId 펀드 ID
     * @return 존재 여부
     */
    @Query("SELECT CASE WHEN COUNT(fp) > 0 THEN true ELSE false END FROM FundPortfolio fp WHERE fp.fund.fundId = :fundId")
    boolean existsByFundId(@Param("fundId") Long fundId);
}
