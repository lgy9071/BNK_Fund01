package com.example.fund.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.Branch;

public interface BranchRepository extends JpaRepository<Branch, Integer>{

}
