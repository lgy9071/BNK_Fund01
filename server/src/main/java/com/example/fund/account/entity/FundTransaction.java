package com.example.fund.account.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.user.entity.User;

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
@Table(name = "fund_transaction")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Oracle 12c+ 가능
    @Column(name = "order_id", nullable = false)
    private Long orderId; // 거래 ID (AUTO_INCREMENT)

//    // FK: 펀드상품 ID
//    @ManyToOne(fetch = FetchType.LAZY)
//    @JoinColumn(name = "fund_id")
//    private Fund fund; // fund_id NUMBER

    // FK: 펀드 계좌 ID
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_account_id")
    private FundAccount fundAccount; // fund_account_id NUMBER

    // FK: 사용자 ID
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user; // user_id NUMBER

    @Column(name = "type", length = 10)
    private String type; // 거래유형 (매수/환매/추가매수 등)

    @Column(name = "amount")
    private BigDecimal amount; // 주문금액 (원 단위)

    @Column(name = "unit_price")
    private BigDecimal unitPrice; // 기준가 (거래일 기준)

    @Column(name = "units", precision = 10, scale = 3)
    private BigDecimal units; // 좌수 (거래금액 ÷ 기준가)

    // FK: 관리 지점
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "branch_id")
    private Branch branch; // branch_id NUMBER

    // FK: 입출금 계좌
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "deposit_account_id")
    private DepositAccount depositAccount; // deposit_account_id NUMBER

    @Column(name = "invest_rule", length = 20)
    private String investRule; // 투자규칙

    @Column(name = "requested_at")
    private LocalDateTime requestedAt; // 접수 시각

    @Column(name = "trade_date")
    private LocalDateTime tradeDate; // 거래일 (컷오프 기준)

    @Column(name = "nav_date")
    private LocalDateTime navDate; // 기준가 적용일

    @Column(name = "processed_at")
    private LocalDateTime processedAt; // 정산일 (실제 체결일)
}
