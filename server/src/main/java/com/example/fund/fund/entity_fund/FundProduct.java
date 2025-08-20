package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "fund_product")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundProduct {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // NUMBER, 시퀀스 기반이면 GenerationType.SEQUENCE 사용
    @Column(name = "product_id")
    private Long productId;

    // Fund 테이블의 fund_id 참조
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    // 이용약관 문서 ID
    @Column(name = "terms_doc_id", nullable = false)
    private Long termsDocId;

    // 투자설명서 문서 ID
    @Column(name = "prospectus_doc_id", nullable = false)
    private Long prospectusDocId;

    // 간이투자설명서 문서 ID
    @Column(name = "summary_doc_id", nullable = false)
    private Long summaryDocId;

    // 상품 상태: DRAFT, SUBMITTED, APPROVED, PUBLISH_PENDING, PUBLISHED, SUSPENDED, RETIRED
    @Column(name = "status", length = 20, nullable = false)
    private String status;
}