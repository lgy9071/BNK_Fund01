package com.example.fund.fund.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.fund.fund.entity.InvestProfileQuestion;

public interface InvestProfileQuestionRepository extends JpaRepository<InvestProfileQuestion, Integer> {
    @Query("SELECT DISTINCT q FROM InvestProfileQuestion q LEFT JOIN FETCH q.options o ORDER BY q.questionId ASC, o.optionId ASC")
    List<InvestProfileQuestion> findAllWithOptions();
}
