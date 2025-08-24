package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.FundAccountTransaction;

public interface FundAccountTransactionRepository extends JpaRepository<FundAccountTransaction, Long>{

}
