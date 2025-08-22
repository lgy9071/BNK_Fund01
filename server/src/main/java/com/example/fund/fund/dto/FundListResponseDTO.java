package com.example.fund.fund.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 펀드 목록 카드/행에 쓰는 요약 DTO
 * - 최신 수익률(1M/3M/12M)은 FundReturn의 최신 base_date에서 가져와 Double로 노출
 * - Fund 엔티티의 fundId는 String이므로 여기서도 String
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FundListResponseDTO {

    /** 펀드 식별자 (Fund.fundId) */
    private String fundId;

    /** 펀드명 */
    private String fundName;

    /** 상품 분류/구분 */
    private String fundType;
    private String fundDivision;

    /** 위험등급 */
    private Integer riskLevel;

    /** 운용사 */
    private String managementCompany;

    /** 설정일(이슈일) */
    private LocalDate issueDate;

    /** 최신 수익률 요약 */
    private Double return1m;
    private Double return3m;
    private Double return12m;
}