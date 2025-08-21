package com.example.fund.account.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.FundAccount;

public interface FundAccountRepository extends JpaRepository<FundAccount, Long> {
	
	boolean existsByFundAccountNumber(String fundAccountNumber);
	
	Optional<FundAccount> findByUser_UserId(Integer userId);
}
