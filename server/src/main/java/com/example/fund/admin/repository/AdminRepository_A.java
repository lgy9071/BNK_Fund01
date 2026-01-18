package com.example.fund.admin.repository;

import com.example.fund.admin.dto.AdminDTO;
import com.example.fund.admin.entity.Admin;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * 관리자(Admin) 엔티티 Repository
 */
public interface AdminRepository_A extends JpaRepository<Admin, Integer> {

    /**
     * 관리자 로그인
     * - adminname + password 기반 조회
     */
    Optional<Admin> findByAdminnameAndPassword(String adminname, String password);

    /**
     * 관리자 아이디 중복 체크
     */
    boolean existsByAdminname(String adminname);

    /**
     * 관리자 역할(role) 기준 페이지네이션 조회
     * - 관리자 설정 화면에서 사용
     */
    Page<Admin> findByRole(String role, Pageable pageable);
}