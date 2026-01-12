package com.example.fund.admin.approval.repository;

import com.example.fund.admin.approval.entity.Approval;
import com.example.fund.admin.repository.projection.StatusCount;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApprovalRepository extends JpaRepository<Approval, Integer> {

    /**
     * 작성자(adminname)가 등록한 결재 목록 조회 (페이징)
     */
    @Query("SELECT a FROM Approval a JOIN a.writer w WHERE w.adminname = :adminname")
    Page<Approval> findByWriterAdminname(@Param("adminname") String adminname, Pageable pageable);

    /**
     * 특정 상태(status)의 결재 목록 조회 (페이징)
     * 승인자/관리자용
     */
    Page<Approval> findByStatus(String status, Pageable pageable);

    /**
     * 작성자 기준으로 특정 상태들을 제외한 결재 목록 조회
     * 예) 배포, 반려 제외 → 진행 중 목록
     */
    Page<Approval> findByWriterAdminnameAndStatusNotIn(String adminname,
                                                       List<String> statuses,
                                                       Pageable pageable);

    /**
     * 작성자 + 상태 조건으로 결재 목록 조회
     */
    Page<Approval> findByWriterAdminnameAndStatus(String adminname,
                                                  String status,
                                                  Pageable pageable);

    /**
     * 작성자 기준 상태별 결재 건수 집계
     * 대시보드 요약용
     */
    @Query("SELECT a.status AS status, COUNT(a) AS cnt " +
            "FROM Approval a WHERE a.writer.adminname = :writer " +
            "GROUP BY a.status")
    List<StatusCount> countByStatusAndWriter(@Param("writer") String writer);

    /**
     * 전체 결재 상태별 건수 집계
     * 승인자/관리자 전체 현황용
     */
    @Query("SELECT a.status AS status, COUNT(a) AS cnt FROM Approval a GROUP BY a.status")
    List<StatusCount> countByStatus();
}
