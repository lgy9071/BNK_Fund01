package com.example.common.dto.fund;

import java.time.LocalDateTime;

import lombok.Data;

@Data
public class QnaDto {
    private Integer qnaId;
    private String title;
    private String content;
    private LocalDateTime regDate;
    private String status;
    private String answer;

    // 생성자
    public QnaDto(Integer qnaId, String title, String content,
            LocalDateTime regDate, String status, String answer) {
        this.qnaId = qnaId;
        this.title = title;
        this.content = content;
        this.regDate = regDate;
        this.status = status;
        this.answer = answer;
    }
}
