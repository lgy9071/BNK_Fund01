package com.example.fund.admin.approval.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * ApprovalLog Entity
 * ---------------------------------
 * 결재 상태 변경 이력을 저장하는 로그 테이블
 *
 * 결재 승인/반려 등 변경 이력 추적
 * 감사(Audit) 목적
 * 승인 프로세스 투명성 확보
 */
@Entity
@Table(name = "approval_log")
@Getter
@Setter
public class ApprovalLog {

    /** 로그 ID (PK) */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer logId;

    /**
     * 어떤 결재에 대한 로그인지
     * - Approval 엔티티와 다대일 관계
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approval_id")
    private Approval approval;

    /** 상태 변경을 수행한 사용자 ID */
    private String changerId;

    /** 변경된 결재 상태 */
    private String status;

    /**
     * 변경 사유
     * - 반려 사유 또는 승인 코멘트
     * - 대용량 텍스트이므로 LOB 사용
     */
    @Lob
    @Column(columnDefinition = "CLOB")
    private String reason;

    /**
     * 상태 변경 시각
     * - 기본값: 현재 시간
     */
    private LocalDateTime changedAt = LocalDateTime.now();
}