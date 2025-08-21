package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.FundTransaction;

public interface FundTransactionRepository extends JpaRepository<FundTransaction, Long> {

}
