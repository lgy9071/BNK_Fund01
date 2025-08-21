package com.example.fund.api.dto.fundStatus;

import java.time.LocalDateTime;

public record FundStatusDetailDto(
        Integer id, String category, String title, String content,
        Integer viewCount, LocalDateTime regdate, LocalDateTime moddate) {
}
