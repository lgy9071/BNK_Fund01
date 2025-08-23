package com.example.fund.account.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "fund_account_transaction")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundAccountTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Oracle 12c 이상에서 IDENTITY 가능, 아니면 시퀀스 사용
    @Column(name = "fund_tx_id", nullable = false, precision = 18, scale = 0)
    private Long fundTxId; // 거래 ID (PK)

    // 펀드 계좌 참조
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "fund_account_id", referencedColumnName = "fund_account_id", nullable = false)
    private FundAccount fundAccount; // 계좌 ID (FK)

    // 거래유형 ENUM → 문자열 저장
    @Enumerated(EnumType.STRING)
    @Column(name = "tx_type", length = 12, nullable = false)
    private TxType txType;

    @Column(name = "amount", precision = 18, scale = 2, nullable = false)
    private BigDecimal amount; // 거래 금액 (음수 금지 로직은 Service 계층에서 검증)

    @Column(name = "counterparty", length = 100, nullable = false)
    private String counterparty; // 상대정보 (상대 계좌 ID 등)
    
    /* 한 건의 Transfer를 묶어주는 ID */
    @Column(name = "transfer_id", length = 36, nullable = false, unique = true)
    private String transferId;
    
    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    // 거래 유형 ENUM
    public enum TxType {
        DEPOSIT,
        WITHDRAW
    }
}
