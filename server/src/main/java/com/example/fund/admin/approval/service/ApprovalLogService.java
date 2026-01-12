package com.example.fund.admin.approval.service;

import com.example.fund.admin.approval.entity.Approval;
import com.example.fund.admin.approval.entity.ApprovalLog;
import com.example.fund.admin.approval.repository.ApprovalLogRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ApprovalLogService {

    private final ApprovalLogRepository approvalLogRepository;

    /**
     * 결재 상태 변경 시 로그 저장
     * - approval : 대상 결재
     * - changerId : 변경자(역할 or 관리자 아이디)
     * - status : 변경된 상태
     * - reason : 승인/반려 사유
     */
    public void saveLog(Approval approval, String changerId, String status, String reason) {
        ApprovalLog log = new ApprovalLog();
        log.setApproval(approval);
        log.setChangerId(changerId);
        log.setStatus(status);
        log.setReason(reason);
        approvalLogRepository.save(log);
    }

    /**
     * 특정 상태로 변경된 모든 로그 조회
     */
    public List<ApprovalLog> findAllByNewStatus(String newStatus) {
        return approvalLogRepository.findByStatusOrderByChangedAtDesc(newStatus);
    }

    /**
     * 특정 상태 + 특정 작성자의 로그 조회
     */
    public List<ApprovalLog> findAllByNewStatusAndWriter(String newStatus, String writer) {
        return approvalLogRepository.findAllByNewStatusAndWriter(newStatus, writer);
    }

    /**
     * 특정 결재 ID 기준 변경 이력 조회
     */
    public List<ApprovalLog> getLogsByApprovalId(Integer approvalId) {
        return approvalLogRepository
                .findByApproval_ApprovalIdOrderByChangedAtDesc(approvalId);
    }
}
