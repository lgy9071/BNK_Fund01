package com.example.common.entity.fund;


import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;


@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Fund extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "fund_id")
    private Long fundId;    // 펀드 ID

    @Column(name = "fund_name", length = 200)
    private String fundName;    // 펀드명

    @Column(name = "fund_type", length = 50)
    private String fundType;    // 펀드 유형

    @Column(name = "investment_region", length = 50)
    private String investmentRegion;    // 펀드 투자 지역

    @Column(name = "establish_date")
    private LocalDate establishDate;    // 펀드 설정일

    @Column(name = "launch_date")       // 삭제 해야 될 수도
    private LocalDate launchDate;       // 펀드 출범일

    @Column(name = "nav", precision = 10, scale = 2)
    private BigDecimal nav;        // 기준가

    @Column(name = "aum", length = 3)
    private Integer aum;                // 순자산

    @Column(name = "total_expense_ratio", precision = 10, scale = 4)
    private BigDecimal totalExpenseRatio;    // 총 보수률

    @Column(name = "risk_level", length = 3)
    private Integer riskLevel;            // 펀드 위험 등급

    @Column(name = "management_company", length = 100)
    private String managementCompany;

//    @JoinColumn(name = "fund_policy_id")
//    @JoinColumn(name = "policy_id")
//    @OneToOne(mappedBy = "fund", fetch = FetchType.LAZY)
//    private FundPolicy fundPolicy;
}

