package com.example.fund.qna.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class QnaCreateRequest {
    @NotBlank private String title;
    @NotBlank private String content;
}
