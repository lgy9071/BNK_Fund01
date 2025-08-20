package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.FundAccount;

public interface FundAccountRepository extends JpaRepository<FundAccount, Long> {
	
	boolean existsByFundAccountNumber(String fundAccountNumber);
}
