package com.example.fund.fund.dto.review;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReviewListResponse {
    private String fundId;
    private int page;
    private int size;
    private long total;
    private List<ReviewItem> items;
}