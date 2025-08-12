package com.example.common.dto.fund;

import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FundListResponse {
    private List<FundPolicyResponseDTO> funds;
    private Integer investType;
    private String investTypeName;
}