package com.example.ap.repository.admin;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.common.entity.admin.AdminNotice;

@Repository
public interface AdminNoticeRepository extends JpaRepository<AdminNotice, Long> {
    // 최신 공지 5건 조회 메서드
    List<AdminNotice> findTop5ByOrderByCreatedAtDesc();
}