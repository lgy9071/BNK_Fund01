package com.example.fund.account.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.account.entity.TransitAccount;

import jakarta.persistence.LockModeType;

public interface TransitAccountRepository extends JpaRepository<TransitAccount, Integer>{

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select t from TransitAccount t where t.transitAccountId = :id")
    Optional<TransitAccount> findByIdForUpdate(@Param("id") Integer id);
}
