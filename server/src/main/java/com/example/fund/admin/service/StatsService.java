package com.example.fund.admin.service;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.admin.dto.PopularFundDto;
import com.example.fund.admin.dto.SalesSeriesDto;
import com.example.fund.admin.repository.StatsRepository;
import com.example.fund.fund.repository_fund.FundProductRepository;
import com.example.fund.fund.repository_fund.FundRepository;
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

    public record FundCountsDto(List<String> labels, List<Long> values) {}
    
    private final StatsRepository repo2;

    public List<PopularFundDto> popularTopN(int limit) {
        int n = (limit <= 0 || limit > 50) ? 5 : limit; // 가드
        return repo2.findPopularFunds(n).stream()
        .map(r -> new PopularFundDto(
            r.getFundId(), r.getFundName(), r.getManagementCompany(),
            r.getClicks(), r.getUsers()))
        .toList();
    }

    private final FundRepository fundRepo;                 // A안
    private final FundProductRepository fundProductRepo;   // A안
    // private final StatsRepository statsRepo;            // B안 사용 시

    public FundCountsDto getFundCounts() {
        // ----- A안: JPA 메서드로 -----
        long total = fundRepo.count();
        long published = fundProductRepo.countPublished();

        // ----- B안: 네이티브 한 방 -----
        // var row = statsRepo.fetchFundCounts();
        // long total = Optional.ofNullable(row.getTotal()).orElse(0L);
        // long published = Optional.ofNullable(row.getPublished()).orElse(0L);

        return new FundCountsDto(
            List.of("전체", "운용중"),
            List.of(total, published)
        );
    }

        private final StatsRepository repo3;

        /** 일별: 최근 N일 */
        public SalesSeriesDto getSalesDaily(int days) {
            int d = Math.max(1, Math.min(days, 365)); // 가드
            return SalesSeriesDto.from(repo3.salesDaily(d));
        }

        /** 월별: 최근 N개월 */
        public SalesSeriesDto getSalesMonthly(int months) {
            int m = Math.max(1, Math.min(months, 60)); // 가드
            return SalesSeriesDto.from(repo3.salesMonthly(m));
        }

        /** 기존 API 호환 (period만 받는 버전) */
        public SalesSeriesDto getSales(String period) {
            if ("monthly".equalsIgnoreCase(period)) {
                return getSalesMonthly(12);
            }
            return getSalesDaily(30);
        }
}

