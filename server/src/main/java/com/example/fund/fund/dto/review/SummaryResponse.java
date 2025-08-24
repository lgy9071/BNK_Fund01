package com.example.fund.fund.dto.review;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SummaryResponse {
    private SummaryStatus status;        // OK | INSUFFICIENT
    private String fundId;
    private String summaryText;          // INSUFFICIENT이면 null
    private OffsetDateTime lastGeneratedAt;
    private Integer reviewCountAtGen;    // 요약 생성 당시 리뷰 수
    private Long activeReviewCount;      // 현재 활성 리뷰 수
}