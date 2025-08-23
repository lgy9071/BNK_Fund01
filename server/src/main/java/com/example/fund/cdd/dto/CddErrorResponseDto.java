package com.example.fund.cdd.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CddErrorResponseDto {
    private boolean success;
    private String message;
    private String errorCode;
}