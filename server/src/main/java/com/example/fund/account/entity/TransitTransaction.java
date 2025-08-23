package com.example.fund.account.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
    name = "transit_transaction",
    indexes = {
    	@Index(name = "ix_transit_account", columnList = "transit_account_id"),
    	@Index(name = "ix_transit_counterparty", columnList = "counterparty"),
        @Index(name = "ix_transit_created", columnList = "created_at")
    }
)
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransitTransaction {

    /** 거래내역 ID (시퀀스 기반 Auto Increment) */
    @Id
    @SequenceGenerator(
        name = "transit_tx_seq_generator",
        sequenceName = "transit_tx_seq",   // DB에 직접 만들어둔 시퀀스명과 동일해야 함
        allocationSize = 1
    )
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "transit_tx_seq_generator")
    @Column(name = "transit_id", nullable = false)
    private Long transitId;
    
    @Column(name = "transit_account_id", nullable = false)
    private Integer transitAccountId;

    /** 거래 상대 계좌 ID (입출금/펀드 등) */
    @Column(name = "counterparty", nullable = false)
    private String counterparty;

    /** 거래 유형: 대기계좌 기준 입금/출금 */
    @Enumerated(EnumType.STRING)
    @Column(name = "tx_type", length = 12, nullable = false)
    private TxType txType; // 거래유형 (입금/출금)

    /** 거래 금액 (0 초과) */
    @DecimalMin(value = "0", inclusive = false, message = "amount는 0보다 커야 합니다.")
    @Column(name = "amount", precision = 18, scale = 0, nullable = false)
    private BigDecimal amount;

    /** 생성일시 */
    @CreationTimestamp
    @Column(name = "created_at", updatable = false, nullable = false)
    private LocalDateTime createdAt;
    
    /* 한 건의 Transfer를 묶어주는 ID */
    @Column(name = "transfer_id", length = 36, nullable = false, unique = true)
    private String transferId;
    
    public enum TxType {
        DEPOSIT,   // 입금
        WITHDRAW   // 출금
    }
}
