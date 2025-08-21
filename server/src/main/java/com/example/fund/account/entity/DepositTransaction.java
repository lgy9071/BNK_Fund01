package com.example.fund.account.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

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
@Table(name = "deposit_transaction")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DepositTransaction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Oracle 12c 이상 가능
    @Column(name = "deposit_tx_id", nullable = false)
    private Long depositTxId; // 거래 ID

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "account_id", nullable = false)
    private DepositAccount account; // 계좌 ID (FK)

    @Column(name = "tx_type", length = 12, nullable = false)
    private String txType; // 거래유형 (입금/출금)

    @Column(name = "amount", precision = 18, scale = 2, nullable = false)
    private BigDecimal amount; // 거래 금액

    @Column(name = "counterparty", length = 100)
    private String counterparty; // 상대정보 (상대 계좌)

    @Column(name = "status", length = 20)
    private String status; // 거래 상태 (PENDING/POSTED/VOID)

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt; // 생성 시각
}
