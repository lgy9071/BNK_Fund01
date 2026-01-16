package com.example.fund.admin.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.admin.dto.PopularFundDto;
import com.example.fund.admin.dto.SalesSeriesDto;
import com.example.fund.admin.service.StatsService;
import com.example.fund.admin.service.StatsService.FundCountsDto;
import com.example.fund.admin.service.StatsService.ProfileDto;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/admin/api/stats")
@RequiredArgsConstructor
public class StatsController {

    // 통계 관련 비즈니스 로직을 담당하는 Service
    private final StatsService statsService;

    /*
     * 투자자 성향(프로필) 통계 조회
     * - GET /admin/api/stats/investor-profiles
     * - 투자자 유형별 비율 또는 분포 데이터 반환
     * - 관리자 대시보드 차트용 API
     */
    @GetMapping("/investor-profiles")
    public List<ProfileDto> investorProfiles() {
        return statsService.getInvestorProfiles();
    }

    /*
     * 인기 펀드 TOP N 조회
     * - GET /admin/api/stats/popular-funds
     * - limit 파라미터로 조회 개수 지정 (기본값 5)
     * - 관리자 페이지 인기 펀드 차트/리스트용
     */
    @GetMapping("/popular-funds")
    public List<PopularFundDto> popularFunds(
            @RequestParam(name = "limit", defaultValue = "5") int limit // 조회할 상위 펀드 개수
    ) {
        return statsService.popularTopN(limit);
    }

    /*
     * 펀드 개수 통계 조회
     * - GET /admin/api/stats/funds-count
     * - 전체 펀드 수, 진행중/종료 펀드 수 등 반환
     */
    @GetMapping("/funds-count")
    public FundCountsDto fundsCount() {
        return statsService.getFundCounts();
    }

    /*
     * 매출(투자 금액) 시계열 통계 조회
     * - GET /admin/api/stats/sales
     *
     * 파라미터 설명:
     * - period : daily(일별) / monthly(월별) (기본값 daily)
     * - days   : 일별 조회 시 최근 N일 (최대 365일)
     * - months : 월별 조회 시 최근 N개월 (최대 60개월)
     *
     * 잘못된 값 방지를 위해 최소/최대 범위 제한 처리
     */
    @GetMapping("/sales")
    public SalesSeriesDto sales(
            @RequestParam(name = "period", defaultValue = "daily") String period, // 조회 단위
            @RequestParam(name = "days",   required = false) Integer days,         // 일별 조회 기간
            @RequestParam(name = "months", required = false) Integer months        // 월별 조회 기간
    ) {

        // 월별 매출 통계 요청일 경우
        if ("monthly".equalsIgnoreCase(period)) {

            // 기본 12개월, 최소 1개월 ~ 최대 60개월 제한
            int m = (months == null ? 12 : Math.max(1, Math.min(months, 60)));

            return statsService.getSalesMonthly(m);
        }

        // 일별 매출 통계 (기본 30일, 최소 1일 ~ 최대 365일 제한)
        int d = (days == null ? 30 : Math.max(1, Math.min(days, 365)));

        return statsService.getSalesDaily(d);
    }
}
