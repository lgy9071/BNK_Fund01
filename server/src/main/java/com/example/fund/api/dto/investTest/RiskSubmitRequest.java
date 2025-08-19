package com.example.fund.api.dto.investTest;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.List;

public record RiskSubmitRequest(
        @NotEmpty List<AnswerItem> answers) {
    public record AnswerItem(
            @NotNull Integer questionId,
            @NotEmpty List<Integer> optionIds // 단일/복수 선택 모두 지원
    ) {
    }
}
