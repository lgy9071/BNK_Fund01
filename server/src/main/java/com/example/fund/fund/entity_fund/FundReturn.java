package com.example.fund.fund.entity_fund;

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
@Table(name = "fund_return")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundReturn {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "fund_return_id")
    private Long fundReturnId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    // 기준일
    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    // 1개월 수익률
    @Column(name = "return_1m", precision = 5, scale = 2)
    private BigDecimal return1m;

    // 3개월 수익률
    @Column(name = "return_3m", precision = 5, scale = 2)
    private BigDecimal return3m;

    // 6개월 수익률
    @Column(name = "return_6m", precision = 5, scale = 2)
    private BigDecimal return6m;

    // 12개월 수익률
    @Column(name = "return_12m", precision = 5, scale = 2)
    private BigDecimal return12m;
}