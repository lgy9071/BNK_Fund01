package com.example.common.entity.fund;

import java.math.BigDecimal;

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
public class FundReturn extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "return_id")
    private Long returnId;	// 고유 번호

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", nullable = false)
    private Fund fund;		// 펀드 번호

    @Column(name = "return_1m", precision = 5, scale = 2)
    private BigDecimal return1m;	// 1개월 수익률

    @Column(name = "return_3m", precision = 5, scale = 2)
    private BigDecimal return3m;	// 3개월 수익률

    @Column(name = "return_6m", precision = 5, scale = 2)
    private BigDecimal return6m;	// 6개월 수익률

    @Column(name = "return_12m", precision = 5, scale = 2)
    private BigDecimal return12m;	// 12개월 수익률

    @Column(name = "return_since", precision = 5, scale = 2)
    private BigDecimal returnSince;	// 누적 수익률
}