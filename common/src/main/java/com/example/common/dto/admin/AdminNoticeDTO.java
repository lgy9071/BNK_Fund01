package com.example.common.dto.admin;

import java.time.LocalDateTime;

import lombok.*;

@Data
public class AdminNoticeDTO {
    private Long id;
    private String title;
    private String content;
    private LocalDateTime createdAt;

    public AdminNoticeDTO(Long id, String title, String content, LocalDateTime createdAt) {
        this.id = id;
        this.title = title;
        this.content = content;
        this.createdAt = createdAt;
    }
}
