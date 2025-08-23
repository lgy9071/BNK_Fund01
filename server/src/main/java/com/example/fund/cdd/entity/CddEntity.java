package com.example.fund.cdd.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "cdd")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CddEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "cdd_id")
    private Long cddId;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "rrn", nullable = false, length = 128)
    private String rrn; // 암호화된 주민등록번호

    @Column(name = "address", nullable = false, length = 255)
    private String address;

    @Column(name = "nationality", nullable = false, length = 50)
    private String nationality;

    @Column(name = "occupation", nullable = false, length = 100)
    private String occupation;

    @Column(name = "income_source", nullable = false, length = 50)
    private String incomeSource;

    @Column(name = "transaction_purpose", nullable = false, length = 100)
    private String transactionPurpose;

    @Column(name = "risk_level", nullable = false, length = 20)
    @Builder.Default
    private String riskLevel = "LOW";

    @Column(name = "risk_score")
    @Builder.Default
    private Integer riskScore = 0;

    @Column(name = "created_at")
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}