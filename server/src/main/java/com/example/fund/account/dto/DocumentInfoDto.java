package com.example.fund.account.dto;

import lombok.*;

@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class DocumentInfoDto {
    private String type;    // "간이투자설명서" / "투자설명서" / "이용약관"
    private String title;   // UI에 표시할 제목 (예: "[필수] 간이투자설명서 동의")
    private String url;     // /fund_document/{fileName}
}