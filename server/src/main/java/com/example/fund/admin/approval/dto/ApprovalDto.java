package com.example.fund.admin.approval.dto;

import lombok.Builder;
import lombok.Data;

/**
 * ApprovalDto
 * ---------------------------------
 * 결재(승인) 정보를 "화면(View) ↔ Controller ↔ Service" 계층에서
 * 안전하게 전달하기 위한 DTO(Data Transfer Object)
 *
 * ✔ Entity를 그대로 노출하지 않기 위해 사용
 * ✔ 필요한 데이터만 담아 전송
 * ✔ 직렬화/역직렬화, API 응답에 적합
 */
@Data
@Builder
public class ApprovalDto {

    /** 결재 고유 ID (PK) */
    private Integer approvalId;

    /** 결재 제목 */
    private String title;

    /** 결재 내용 */
    private String content;

    /** 작성자 ID (Admin의 admin_id 값) */
    private String writerId;

    /** 결재 상태 (예: WAITING, APPROVED, REJECTED) */
    private String status;
}