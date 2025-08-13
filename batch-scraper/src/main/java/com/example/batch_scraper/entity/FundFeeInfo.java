package com.example.batch_scraper.entity;

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
@Table(name = "fund_fee_info")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundFeeInfo {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    @Column(name = "fund_fee_info_id")
    private Long fundFeeInfoId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    // 운용 보수
    @Column(name = "management_fee", precision = 5, scale = 3)
    private BigDecimal managementFee;

    // 판매 보수
    @Column(name = "sales_fee", precision = 5, scale = 3)
    private BigDecimal salesFee;

    // 일반 사무 관리 보수
    @Column(name = "admin_fee", precision = 5, scale = 3)
    private BigDecimal adminFee;

    // 수탁 보수
    @Column(name = "trust_fee", precision = 5, scale = 3)
    private BigDecimal trustFee;

    // 총 보수
    @Column(name = "total_fee", precision = 5, scale = 3)
    private BigDecimal totalFee;

    // 총 비용 비율
    @Column(name = "ter", precision = 5, scale = 3)
    private BigDecimal ter;

    // 선취 수수료
    @Column(name = "front_load_fee", precision = 5, scale = 2)
    private BigDecimal frontLoadFee;

    // 후취 수수료
    @Column(name = "rear_load_fee", precision = 5, scale = 2)
    private BigDecimal rearLoadFee;
}