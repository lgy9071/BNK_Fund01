package com.example.fund.fund.repository_fund_etc;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.fund.fund.entity_fund_etc.InvestProfileQuestion;

public interface InvestProfileQuestionRepository extends JpaRepository<InvestProfileQuestion, Integer>{
	@Query("SELECT DISTINCT q FROM InvestProfileQuestion q LEFT JOIN FETCH q.options")
    List<InvestProfileQuestion> findAllWithOptions();
}
