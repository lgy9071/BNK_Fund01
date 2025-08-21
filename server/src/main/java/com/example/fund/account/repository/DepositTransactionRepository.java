package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.DepositTransaction;

public interface DepositTransactionRepository extends JpaRepository<DepositTransaction, Long> {

}
