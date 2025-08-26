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

    private final StatsService statsService;

    // GET /admin/api/stats/investor-profiles
    @GetMapping("/investor-profiles")
    public List<ProfileDto> investorProfiles() {
        return statsService.getInvestorProfiles();
    }

    @GetMapping("/popular-funds")
    public List<PopularFundDto> popularFunds(
        @RequestParam(name = "limit", defaultValue = "5") int limit) { // ← name 지정
        return statsService.popularTopN(limit);
    }

    @GetMapping("/funds-count")
    public FundCountsDto fundsCount() {
        return statsService.getFundCounts();
    }

    @GetMapping("/sales")
    public SalesSeriesDto sales(
        @RequestParam(name = "period", defaultValue = "daily") String period,
        @RequestParam(name = "days",   required = false) Integer days,
        @RequestParam(name = "months", required = false) Integer months
    ) {
        if ("monthly".equalsIgnoreCase(period)) {
            int m = (months == null ? 12 : Math.max(1, Math.min(months, 60)));
            return statsService.getSalesMonthly(m);
        }
        int d = (days == null ? 30 : Math.max(1, Math.min(days, 365)));
        return statsService.getSalesDaily(d);
    }
}