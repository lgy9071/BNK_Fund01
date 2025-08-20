package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.TransitAccount;

public interface TransitAccountRepository extends JpaRepository<TransitAccount, Integer>{

}
