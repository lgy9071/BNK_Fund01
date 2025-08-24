package com.example.fund.fund.entity_fund;

import java.time.OffsetDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "REVIEW_AI_SUMMARY",
       uniqueConstraints = @UniqueConstraint(name="UQ_REVIEW_AI_SUMMARY_FUND", columnNames = "FUND_ID"))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class ReviewAiSummary {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "SUMMARY_ID")
    private Long summaryId;

    @Column(name = "FUND_ID", length = 20, nullable = false)
    private String fundId;

    @Lob
    @Column(name = "SUMMARY_TEXT", nullable = false)
    private String summaryText;

    @Column(name = "LAST_GENERATED_AT", nullable = false)
    private OffsetDateTime lastGeneratedAt;

    @Column(name = "REVIEW_COUNT_AT_GEN", nullable = false)
    private Integer reviewCountAtGen;

    @Column(name = "MODEL_PROVIDER")
    private String modelProvider;

    @Column(name = "MODEL_NAME")
    private String modelName;
}