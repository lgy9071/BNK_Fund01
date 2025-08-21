package com.example.fund.fund.repository_fund_etc;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.fund.entity_fund_etc.InvestProfileHistory;
import com.example.fund.user.entity.User;

public interface InvestProfileHistoryRepository extends JpaRepository<InvestProfileHistory, Integer> {
    Page<InvestProfileHistory> findByUser(User user, Pageable pageable);
}
