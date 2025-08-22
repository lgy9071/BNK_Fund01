package com.example.fund.admin.service;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.fund.repository_fund_etc.InvestProfileHistoryRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class StatsService {

    private final InvestProfileHistoryRepository repo;

    // 임시 라벨 매핑 (마스터 테이블 있으면 JOIN으로 대체 권장)
    private static final Map<Long, String> TYPE_LABELS = Map.of(
        11L, "안정형",
        12L, "안정추구형",
        13L, "위험중립형",
        14L, "적극투자형",
        15L, "공격투자형"
    );

    public List<ProfileDto> getInvestorProfiles() {
        return repo.countByType().stream()
            .map(r -> new ProfileDto(
                TYPE_LABELS.getOrDefault(safeLong(r.getTypeId()), "기타(" + safeLong(r.getTypeId()) + ")"),
                safeLong(r.getCnt())
            ))
            // 필요 시 보기 좋게 라벨순 정렬
            .sorted(Comparator.comparing(ProfileDto::label))
            .toList();
    }

    // 리포지토리 프로젝션 타입 안전 변환 (COUNT(*)가 BigDecimal로 오는 환경 대비)
    private static long safeLong(Object v) {
        if (v == null) return 0L;
        if (v instanceof Long l) return l;
        if (v instanceof Integer i) return i.longValue();
        if (v instanceof BigDecimal b) return b.longValue();
        return Long.parseLong(v.toString());
    }

    public record ProfileDto(String label, long value) {}
}

