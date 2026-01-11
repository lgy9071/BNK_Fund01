package com.example.fund.admin.approval.entity;

import com.example.fund.admin.entity.Admin;
import com.example.fund.common.entity.BaseEntity;
import com.example.fund.fund.entity_fund.Fund;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Approval Entity
 * ---------------------------------
 * 관리자 결재(승인) 정보를 DB 테이블(tbl_approval)과 매핑하는 엔티티
 *
 * 실제 DB 구조와 1:1 대응
 * JPA/Hibernate가 관리
 * 비즈니스 로직의 핵심 데이터 모델
 */
@Entity
@Table(name = "tbl_approval")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Approval extends BaseEntity {

    /** 결재 ID (PK, Auto Increment) */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer approvalId;

    /** 결재 제목 */
    @Column(length = 100, nullable = false)
    private String title;

    /** 결재 내용 */
    @Column(length = 100, nullable = false)
    private String content;

    /**
     * 결재 작성자
     * - Admin 엔티티와 다대일 관계
     * - writer_id 컬럼이 admin 테이블의 admin_id를 참조
     */
    @ManyToOne
    @JoinColumn(name = "writer_id", referencedColumnName = "admin_id")
    private Admin writer;

    /**
     * 결재 상태
     * 예: WAITING / APPROVED / REJECTED
     */
    @Column(length = 20, nullable = false)
    private String status;

    /**
     * 반려 사유
     * - 결재가 REJECTED 상태일 때 사용
     * - 최대 200자
     */
    @Column(length = 200)
    private String rejectReason;

    /**
     * 결재 대상 펀드
     * - Fund 엔티티와 다대일 관계
     * - 지연 로딩(LAZY) 적용
     */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id")
    private Fund fund;
}