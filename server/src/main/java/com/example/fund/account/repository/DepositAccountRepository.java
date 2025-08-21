package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.DepositAccount;

public interface DepositAccountRepository extends JpaRepository<DepositAccount, Long>{

}
