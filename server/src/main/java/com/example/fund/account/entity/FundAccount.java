package com.example.fund.account.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import com.example.fund.user.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name = "fund_account")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class FundAccount {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) 
    @Column(name = "fund_account_id", nullable = false)
    private Long fundAccountId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

//    @ManyToOne(fetch = FetchType.LAZY)
//    @JoinColumn(name = "fund_product_id", nullable = false)
//    private Fund fundProduct;

    @Column(name = "fund_account_number", length = 32, unique = true, nullable = false)
    private String fundAccountNumber;

    @Column(name = "fund_pin_hash", length = 60, nullable = false)
    private String fundPinHash; // BCrypt 해시

    @Column(name = "units", precision = 18, scale = 4, nullable = false)
    private BigDecimal units; // 좌수 (소수점 4자리)

    @Column(name = "locked_units", precision = 18, scale = 4, nullable = false)
    private BigDecimal lockedUnits;

    @Column(name = "available_amount", precision = 18, scale = 0, nullable = false)
    private BigDecimal availableAmount; // 출금 가능 금액 (정수, 소수 없음)

    @Column(name = "total_invested", precision = 18, scale = 0, nullable = false)
    private BigDecimal totalInvested;// 총 투자 금액

    @Column(name = "avg_unit_price", precision = 18, scale = 2, nullable = false)
    private BigDecimal avgUnitPrice; // 기준가/평가액 (소수점 2자리)
    
    @Column(name = "fund_valuation", precision = 18, scale = 2, nullable = false)
    private BigDecimal fundValuation; // 현재 평가 금액

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 10, nullable = false)
    private FundAccountStatus status; // NORMAL / CLOSED

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt; // 개설일

    @Column(name = "terminated_at")
    private LocalDateTime terminatedAt; // 해지일
    
    public enum FundAccountStatus {
        NORMAL,   // 정상
        CLOSED    // 해지
    }
}
