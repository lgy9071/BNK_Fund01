package com.example.fund.account.dto;

import com.example.fund.account.entity.DepositAccount;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// 계좌 조회 응답 DTO
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DepositAccountResponseDto {
    private Long accountId;
    private Integer userId;
    private String accountNumber;
    private String accountName;
    private BigDecimal balance;
    private LocalDateTime createdAt;
    private String status;

    // Entity to DTO 변환 메서드
    public static DepositAccountResponseDto fromEntity(DepositAccount account) {
        return DepositAccountResponseDto.builder()
                .accountId(account.getAccountId())
                .userId(account.getUser().getUserId())
                .accountNumber(account.getAccountNumber())
                .accountName(account.getAccountName())
                .balance(account.getBalance())
                .createdAt(account.getCreatedAt())
                .status(account.getStatus().name())
                .build();
    }
}