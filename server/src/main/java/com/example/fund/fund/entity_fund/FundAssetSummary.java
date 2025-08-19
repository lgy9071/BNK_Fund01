package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "fund_asset_summary")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundAssetSummary {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "fund_asset_summary_id")
    private Long fundAssetSummaryId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    @Column(name = "stock_ratio", precision = 5, scale = 2)
    private BigDecimal stockRatio;

    @Column(name = "bond_ratio", precision = 5, scale = 2)
    private BigDecimal bondRatio;

    @Column(name = "cash_ratio", precision = 5, scale = 2)
    private BigDecimal cashRatio;

    @Column(name = "etc_ratio", precision = 5, scale = 2)
    private BigDecimal etcRatio;
}