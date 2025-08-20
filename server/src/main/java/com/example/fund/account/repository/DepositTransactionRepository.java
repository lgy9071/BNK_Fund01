package com.example.fund.account.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.DepositTransaction;

public interface DepositTransactionRepository extends JpaRepository<DepositTransaction, Long> {
	
//	Optional<DepositTransaction> findByUser_UserId(Integer userId);
}