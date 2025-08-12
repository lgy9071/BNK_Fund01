package com.example.ap.repository.fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.common.entity.fund.InvestProfileType;

public interface InvestProfileTypeRepository extends JpaRepository<InvestProfileType, Integer> {
	// 총점 기준으로 타입 찾기
	@Query("SELECT t FROM InvestProfileType t WHERE :score BETWEEN t.minScore AND t.maxScore")
	Optional<InvestProfileType> findByScore(@Param("score") Integer score);
}
