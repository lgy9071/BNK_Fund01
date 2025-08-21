package com.example.fund.api.dto.investTest;

import java.util.List;

public record RiskResultView(
                Integer resultId,
                int totalScore,
                String grade, // typeName
                String description, // 필요 시 description 요약 등으로 교체 가능
                List<String> recommendations,
                String createdAt) {
}
