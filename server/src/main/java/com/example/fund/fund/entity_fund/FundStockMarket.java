package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "fund_stock_market")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundStockMarket {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "fund_stock_market_id")
    private Long fundStockMarketId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    @Column(name = "kse_ratio", precision = 5, scale = 2)
    private BigDecimal kseRatio;

    @Column(name = "kosdaq_ratio", precision = 5, scale = 2)
    private BigDecimal kosdaqRatio;

    @Column(name = "other_ratio", precision = 5, scale = 2)
    private BigDecimal otherRatio;
}