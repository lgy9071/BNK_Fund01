package com.example.fund.account.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transit_transaction")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TransitTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // 오라클이면 보통 SEQUENCE 전략 사용
    @Column(name = "transit_id")
    private Long transitId;   // 거래내역 ID

    @Column(name = "from_account_id")
    private Long fromAccountId;   // 출금 예정 계좌 ID

    @Column(name = "to_account_id")
    private Long toAccountId;     // 입금 계좌 ID

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    private FundTransaction order;         // 관련 주문 (매수/환매 주문 FK)

    @Column(name = "amount", precision = 18, scale = 0, nullable = false)
    private BigDecimal amount;    // 거래 금액

    @Enumerated(EnumType.STRING)
    @Column(name = "trade_status", length = 20, nullable = false)
    private TradeStatus tradeStatus = TradeStatus.PENDING;  // 거래 상태: 대기/완료/취소

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;  // 생성일시

    @Column(name = "transit_at")
    private LocalDateTime transitAt;  // 거래상태 변화 일시

    // === Enum 정의 ===
    public enum TradeStatus {
        PENDING,   // 대기
        COMPLETED, // 완료
        CANCELED   // 취소
    }

    // === 생성 시 자동 세팅 ===
    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();
    }
}
