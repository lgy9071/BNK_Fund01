package com.example.fund.api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import com.example.fund.api.entity.RefreshTokenEntity;

public interface RefreshTokenRepository extends JpaRepository<RefreshTokenEntity, String> {
    boolean existsByTokenHash(String tokenHash);

    List<RefreshTokenEntity> findAllByUserIdAndRevokedFalse(Integer userId);

    int deleteByUserId(Integer userId); // 선택: 계정 전체 로그아웃 등에 사용

}
