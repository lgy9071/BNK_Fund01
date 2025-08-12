package com.example.common.dto.fund;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class InvestTypeResponse {
    private boolean hasProfile;
    private Integer investType;
    private String investTypeName;
}
