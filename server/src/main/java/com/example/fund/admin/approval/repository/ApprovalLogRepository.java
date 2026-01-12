package com.example.fund.admin.approval.repository;

import com.example.fund.admin.approval.entity.ApprovalLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

/**
 * 결재 상태 변경 이력(ApprovalLog)을 관리하는 JPA Repository
 */
public interface ApprovalLogRepository extends JpaRepository<ApprovalLog, Integer> {

    /**
     * 특정 결재(approvalId)에 대한 모든 변경 이력을
     * 최신 변경 순(변경일 DESC)으로 조회
     */
    List<ApprovalLog> findByApproval_ApprovalIdOrderByChangedAtDesc(Integer approvalId);

    /**
     * 특정 상태(status)로 변경된 모든 로그를
     * 최신 변경 순으로 조회
     * 예) 배포대기, 반려, 배포
     */
    List<ApprovalLog> findByStatusOrderByChangedAtDesc(String status);

    /**
     * 특정 상태(status) + 특정 작성자(writer)의 결재 로그 조회
     * → 작성자 기준 평균 처리일 계산 등에 사용
     */
    @Query("SELECT l FROM ApprovalLog l " +
            "WHERE l.status = :status " +
            "AND l.approval.writer.adminname = :writer")
    List<ApprovalLog> findAllByNewStatusAndWriter(@Param("status") String status,
                                                  @Param("writer") String writer);
}
