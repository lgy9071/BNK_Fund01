package com.example.fund.admin.dto;

public record PopularFundDto(
        // 펀드 고유 식별자
        String id,

        // 펀드 이름
        String name,

        // 운용사(회사) 이름
        String company,

        // 조회 수 (클릭 횟수)
        long clicks,

        // 펀드를 조회한 사용자 수
        long users
) {}
