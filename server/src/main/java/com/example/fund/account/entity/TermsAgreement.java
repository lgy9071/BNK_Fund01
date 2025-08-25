// src/main/java/com/example/fund/agreement/entity/TermsAgreement.java
package com.example.fund.account.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(
    name = "terms_agreement",
    indexes = {
        @Index(name = "ix_terms_user", columnList = "user_id"),
        @Index(name = "ix_terms_fund", columnList = "product_id")
    }
)

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class TermsAgreement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "agree_id", nullable = false)
    private Long agreeId;

    @Column(name = "user_id", nullable = false)
    private Integer userId;

    @Column(name = "product_id", nullable = false)
    private Long productId;

    @Column(name = "agreed_at", nullable = false)
    private LocalDateTime agreedAt;

    @Column(name = "expired_at", nullable = false)
    private LocalDateTime expiredAt; // 당일 자정

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean isActive = true;
}
