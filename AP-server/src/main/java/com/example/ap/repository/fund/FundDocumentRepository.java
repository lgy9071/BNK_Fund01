package com.example.ap.repository.fund;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.common.entity.fund.FundDocument;

@Repository
public interface FundDocumentRepository extends JpaRepository<FundDocument, Long>{

    List<FundDocument> findByFund_FundId(Long fundId);

    void deleteByFund_FundIdAndDocType(Long fundId, String docType);
}
