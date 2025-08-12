package com.example.ap.repository.admin;


import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.example.ap.repository.admin.projection.StatusCount;
import com.example.common.entity.admin.Approval;

@Repository
public interface ApprovalRepository extends JpaRepository<Approval, Integer> {

    @Query("SELECT a FROM Approval a JOIN a.writer w WHERE w.adminname = :adminname")
    Page<Approval> findByWriterAdminname(@Param("adminname") String adminname, Pageable pageable);

    Page<Approval> findByStatus(String status, Pageable pageable);

    Page<Approval> findByWriterAdminnameAndStatusNotIn(String adminname, List<String> statuses, Pageable pageable);

    Page<Approval> findByWriterAdminnameAndStatus(String adminname, String status, Pageable pageable);

    // 상태별 개수 집계 프로젝션
    @Query("SELECT a.status AS status, COUNT(a) AS cnt " +
            "FROM Approval a WHERE a.writer.adminname = :writer " +
            "GROUP BY a.status")
    List<StatusCount> countByStatusAndWriter(@Param("writer") String writer);

    @Query("SELECT a.status AS status, COUNT(a) AS cnt FROM Approval a GROUP BY a.status")
    List<StatusCount> countByStatus();
}
