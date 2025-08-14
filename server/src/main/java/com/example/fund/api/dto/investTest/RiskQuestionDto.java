package com.example.fund.api.dto.investTest;

import java.util.List;

public record RiskQuestionDto(
        Integer id,
        String title,
        List<RiskOptionDto> options) {
}
