package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "fund_liquidity_assets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundLiquidityAssets {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "fund_liquidity_assets_id")
    private Long fundLiquidityAssetsId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    @Column(name = "cd_ratio", precision = 5, scale = 2)
    private BigDecimal cdRatio;

    @Column(name = "cp_ratio", precision = 5, scale = 2)
    private BigDecimal cpRatio;

    @Column(name = "call_loan_ratio", precision = 5, scale = 2)
    private BigDecimal callLoanRatio;

    @Column(name = "deposit_ratio", precision = 5, scale = 2)
    private BigDecimal depositRatio;

    @Column(name = "other_ratio", precision = 5, scale = 2)
    private BigDecimal otherRatio;
}