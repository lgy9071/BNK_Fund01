package com.example.common.entity.fund;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "fund_document")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "document_id")
    private Long documentId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "doc_type", length = 50)
    private String docType;

    @Column(name = "doc_title", length = 200)
    private String docTitle;

    @Column(name = "file_path", length = 300)
    private String filePath;

    @Column(name = "file_format", length = 10)
    private String fileFormat;

    @Column(name = "uploaded_at")
    private LocalDate uploadedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    public void onCreate() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    public void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
