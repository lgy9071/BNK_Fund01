package com.example.fund.fund.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class FundProductView {
    private Long productId;
    private String status;

    @JsonProperty("docs")         // ← JSON 키를 docs로 강제
    private List<FundProductDocDto> documents;
}