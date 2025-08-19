package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.FundDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FundDocumentRepository extends JpaRepository<FundDocument, Long> {

}
