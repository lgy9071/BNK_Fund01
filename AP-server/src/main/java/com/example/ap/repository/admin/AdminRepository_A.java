package com.example.ap.repository.admin;

import java.util.Optional;

import org.springframework.boot.autoconfigure.kafka.KafkaProperties.Admin;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AdminRepository_A extends JpaRepository<Admin, Integer> {

    Optional<Admin> findByAdminnameAndPassword(String adminname, String password); //로그인

    boolean existsByAdminname(String adminname); //아이디 중복체크

    //List<Admin> findByRole(String role);

    Page<Admin> findByRole(String role, Pageable pageable); //관리자 설정 페이지네이션
}
