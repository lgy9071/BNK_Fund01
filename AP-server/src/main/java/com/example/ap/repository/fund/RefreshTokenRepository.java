package com.example.ap.repository.fund;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.RefreshTokenEntity;

public interface RefreshTokenRepository extends JpaRepository<RefreshTokenEntity, String> {
    boolean existsByTokenHash(String tokenHash);

    List<RefreshTokenEntity> findAllByUserIdAndRevokedFalse(Integer userId);

    int deleteByUserId(Integer userId); // 선택: 계정 전체 로그아웃 등에 사용
}
