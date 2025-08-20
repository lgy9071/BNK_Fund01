package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.TransitTransaction;

public interface TransitTransactionRepository extends JpaRepository<TransitTransaction, Long> {

}
