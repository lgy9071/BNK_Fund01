package com.example.batch_scraper.entity;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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