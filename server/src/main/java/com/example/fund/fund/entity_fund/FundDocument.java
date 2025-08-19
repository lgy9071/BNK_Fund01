package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

/** 공시자료 */
@Entity
@Table(name = "fund_document")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundDocument {
    // 공시자료 고유 번호
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "doc_id")
    private Long docId;

    // 문서 유형: 이용약관 / 투자설명서 / 간이투자설명서
    @Column(name = "doc_type", length = 30, nullable = false)
    private String docType;

    // 저장 디렉터리 경로
    @Column(name = "file_path", length = 200, nullable = false)
    private String filePath;

    // 실제 파일명
    @Column(name = "file_name", length = 100, nullable = false)
    private String fileName;
}
../fund_document
