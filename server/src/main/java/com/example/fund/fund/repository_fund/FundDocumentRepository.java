package com.example.fund.fund.repository_fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.fund.fund.entity_fund.FundDocument;

@Repository
public interface FundDocumentRepository extends JpaRepository<FundDocument, Long> {
	
	
	 // ① FundDocument에 Fund 연관이 있는 경우 (예: @ManyToOne Fund fund; Fund에 fundId 있음)
    //Optional<FundDocument> findFirstByFund_FundIdAndDocType(String fundId, String docType);

    // ② FundDocument에 직접 fundId 컬럼이 있는 경우 (엔티티에 field 추가 필요)
    //Optional<FundDocument> findFirstByFundIdAndDocType(String fundId, String docType);
}
