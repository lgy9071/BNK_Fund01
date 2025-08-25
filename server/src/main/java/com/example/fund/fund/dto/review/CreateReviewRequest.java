package com.example.fund.fund.dto.review;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CreateReviewRequest {
    @NotBlank(message = "리뷰는 비어 있을 수 없습니다.")
    @Size(min = 1, max = 100, message = "리뷰는 1~100자여야 합니다.")
    private String text;
}