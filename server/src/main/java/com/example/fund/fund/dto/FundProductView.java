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

    // JSON에 'docs' 한 가지만 노출
    private java.util.List<FundProductDocDto> docs;
}