package com.example.fund.fund.entity_fund;

import java.time.OffsetDateTime;


import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "FUND_REVIEW",
       uniqueConstraints = @UniqueConstraint(name = "UQ_FUND_REVIEW_ONE_PER_USER", columnNames = {"FUND_ID","USER_ID"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FundReview {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "REVIEW_ID")
    private Long reviewId;

    @Column(name = "FUND_ID", length = 20, nullable = false)
    private String fundId;

    @Column(name = "USER_ID", nullable = false)
    private Integer userId;  // ← Integer로 교정

    @Column(name = "REVIEW_TEXT", length = 100, nullable = false)
    private String reviewText;

    @Column(name = "CREATED_AT", nullable = false)
    private OffsetDateTime createdAt;

    @Column(name = "UPDATED_AT")
    private OffsetDateTime updatedAt;

    @Column(name = "EDIT_COUNT", nullable = false)
    private Integer editCount;

    @Column(name = "DELETED_AT")
    private OffsetDateTime deletedAt;

    @PrePersist
    void onCreate() {
        this.createdAt = OffsetDateTime.now();
        if (this.editCount == null) this.editCount = 0;
    }
}