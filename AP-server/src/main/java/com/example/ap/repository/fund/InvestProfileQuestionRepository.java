package com.example.ap.repository.fund;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.common.entity.fund.InvestProfileQuestion;

public interface InvestProfileQuestionRepository extends JpaRepository<InvestProfileQuestion, Integer>{
	@Query("SELECT DISTINCT q FROM InvestProfileQuestion q LEFT JOIN FETCH q.options")
    List<InvestProfileQuestion> findAllWithOptions();
}
