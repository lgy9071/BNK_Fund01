package com.example.fund.fund.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.util.List;

@Getter
@AllArgsConstructor
public class FundProductView {
    private Long productId;
    private String status;
    private List<FundProductDocDto> documents;
}