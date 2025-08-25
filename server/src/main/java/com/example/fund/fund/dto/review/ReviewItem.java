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
public class ReviewItem {
    private Long reviewId;
    private Integer userId;
    private String fundId;
    private String text;
    private OffsetDateTime createdAt;
    private Integer editCount;
}