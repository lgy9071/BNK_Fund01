package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

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

    // 기준일
    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    // 기준가
    @Column(name = "nav_price", precision = 10, scale = 2)
    private BigDecimal navPrice;

    // 순 자산 총액
    @Column(name = "nav_total", precision = 10, scale = 2)
    private BigDecimal navTotal;

    // 설정 원본
    @Column(name = "original_principal", precision = 10, scale = 2)
    private BigDecimal originalPrincipal;

    // 전일 대비 절대값
    @Column(name = "nav_change_1d", precision = 12, scale = 4)
    private BigDecimal navChange1d;

    // 전일 대비 등락률 (%)
    @Column(name = "nav_change_rate_1d", precision = 5, scale = 2)
    private BigDecimal navChangeRate1d;

    // 전주 대비 절대값
    @Column(name = "nav_change_1w", precision = 12, scale = 4)
    private BigDecimal navChange1w;

    // 전주 대비 등락률 (%)
    @Column(name = "nav_change_rate_1w", precision = 5, scale = 2)
    private BigDecimal navChangeRate1w;
}
