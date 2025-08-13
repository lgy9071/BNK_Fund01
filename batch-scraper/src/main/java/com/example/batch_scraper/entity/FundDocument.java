package com.example.batch_scraper.entity;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** 공시자료 */
@Entity
@Table(name = "fund_document")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor
@Builder
public class FundDocument {

    /** 공시자료 고유 번호 */
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long docId;

    /** 펀드 FK */
    @Column(name = "fund_id", length = 20, nullable = false)
    private String fundId;

    /** 문서 유형: 이용약관 / 투자설명서 / 간이투자설명서 */
    @Column(name = "doc_type", length = 30, nullable = false)
    private String docType;

    /** 저장 디렉터리 경로 */
    @Column(name = "file_path", length = 200, nullable = false)
    private String filePath;

    /** 실제 파일명 */
    @Column(name = "file_name", length = 100, nullable = false)
    private String fileName;

    /** 시스템 업로드 시각 */
    @Column(name = "uploaded_at", nullable = false,
            columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime uploadedAt;
}
