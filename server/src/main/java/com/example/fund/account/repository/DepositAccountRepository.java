package com.example.fund.account.repository;

import java.math.BigDecimal;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.DepositAccount;

public interface DepositAccountRepository extends JpaRepository<DepositAccount, Long>{
	
	boolean existsByUser_UserId(Integer userId);
	
	Optional<DepositAccount> findByUser_UserId(Integer userId);
	Optional<Long> findDepositAccountByUser_UserId(Integer userId);
	BigDecimal findBalanceByUser_UserId(Integer userId);
}
