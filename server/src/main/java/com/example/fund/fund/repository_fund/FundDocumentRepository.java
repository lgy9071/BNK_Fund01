package com.example.fund.fund.repository_fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.fund.fund.entity_fund.FundDocument;

@Repository
public interface FundDocumentRepository extends JpaRepository<FundDocument, Long> {
	
	
}
