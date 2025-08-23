package com.example.fund.account.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// 계좌 생성 응답 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateDepositAccountResponseDto {
    private Long accountId;
    private Integer userId;
    private String accountNumber;
    private String accountName;
    private BigDecimal balance;
    private LocalDateTime createdAt;
    private String status;
}