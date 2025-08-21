package com.example.fund.api.dto.fundStatus;

import java.time.LocalDateTime;

public record FundStatusListItemDto(
        Integer id, String category, String title,
        String preview, Integer viewCount, LocalDateTime regdate) {
}
