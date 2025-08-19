package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "fund_price_daily")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundPriceDaily {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "fund_price_daily_id")
    private Long fundPriceDailyId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    @Column(name = "nav_price", precision = 10, scale = 2)
    private BigDecimal navPrice;

    @Column(name = "nav_change", precision = 10, scale = 2)
    private BigDecimal navChange;

    @Column(name = "tax_price", precision = 10, scale = 2)
    private BigDecimal taxPrice;

    @Column(name = "original_principal", precision = 10, scale = 2)
    private BigDecimal originalPrincipal;

    @Column(name = "kospi", precision = 10, scale = 2)
    private BigDecimal kospi;

    @Column(name = "kospi200", precision = 10, scale = 2)
    private BigDecimal kospi200;

    @Column(name = "kosdaq", precision = 10, scale = 2)
    private BigDecimal kosdaq;

    @Column(name = "treasury_3y", precision = 10, scale = 3)
    private BigDecimal treasury3y;

    @Column(name = "corp_bond_3y", precision = 10, scale = 3)
    private BigDecimal corpBond3y;
}