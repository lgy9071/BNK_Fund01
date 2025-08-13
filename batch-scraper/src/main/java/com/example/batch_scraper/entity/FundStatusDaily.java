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
@Table(name = "fund_status_daily")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundStatusDaily {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "fund_status_daily_id")
    private Long fundStatusDailyId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;
    
    @Column(name = "nav_price", precision = 10, scale = 2)
    private BigDecimal navPrice;

    @Column(name = "nav_total", precision = 10, scale = 2)
    private BigDecimal navTotal;

    @Column(name = "original_principal", precision = 10, scale = 2)
    private BigDecimal originalPrincipal;

    @Column(name = "nav_change_1d", precision = 12, scale = 4)
    private BigDecimal navChange1d;           // 전일 대비 절대값

    @Column(name = "nav_change_rate_1d", precision = 5, scale = 2)
    private BigDecimal navChangeRate1d;       // 전일 대비 등락률 (%)

    @Column(name = "nav_change_1w", precision = 12, scale = 4)
    private BigDecimal navChange1w;           // 전주 대비 절대값

    @Column(name = "nav_change_rate_1w", precision = 5, scale = 2)
    private BigDecimal navChangeRate1w;       // 전주 대비 등락률 (%)
}
