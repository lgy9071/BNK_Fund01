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