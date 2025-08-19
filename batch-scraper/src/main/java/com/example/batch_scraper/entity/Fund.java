package com.example.batch_scraper.entity;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "fund")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Fund {
	// 펀드 고유 번호
    @Id
    @Column(name = "fund_id", length = 20)
    private String fundId;

    // 펀드명
    @Column(name = "fund_name", length = 150)
    private String fundName;

    // 펀드 상품 분류
    @Column(name = "fund_type", length = 20)
    private String fundType;

    // 구분
    @Column(name = "fund_division", length = 20)
    private String fundDivision;

    // 투자 지역
    @Column(name = "investment_region", length = 20)
    private String investmentRegion;

    // 판매 지역 구분
    @Column(name = "sales_region_type", length = 20)
    private String salesRegionType;

    // 분류 코드
    @Column(name = "group_code", length = 30)
    private String groupCode;

    // 단축 코드
    @Column(name = "short_code", length = 10)
    private String shortCode;

    // 설정일
    @Column(name = "issue_date")
    private LocalDate issueDate;

    // 최초 설정 기준 가격
    @Column(name = "initial_nav_price", precision = 10, scale = 2)
    private BigDecimal initialNavPrice;

    // 신탁기간(월)
    @Column(name = "trust_term")
    private Integer trustTerm;

    // 신탁 회계 기간(월)
    @Column(name = "accounting_period")
    private Integer accountingPeriod;

    // 특성 분류
    @Column(name = "fund_class", length = 50)
    private String fundClass;

    // 공모/사모 구분
    @Column(name = "public_type", length = 20)
    private String publicType;

    // 추가/단위형 구분
    @Column(name = "add_unit_type", length = 10)
    private String addUnitType;

    // 운용상태
    @Column(name = "fund_status", length = 20)
    private String fundStatus;

    // 위험 등급
     @Column(name = "risk_level")
     private Integer riskLevel;

    // 운용 실적 공시 분류
    @Column(name = "performance_disclosure", length = 50)
    private String performanceDisclosure;

    // 운용사 이름
    @Column(name = "management_company", length = 100)
    private String managementCompany;
    
    // 최소 가입 금액
    @Column(name = "min_subscription_amount", precision = 15, scale = 2)
    private BigDecimal minSubscriptionAmount;
}