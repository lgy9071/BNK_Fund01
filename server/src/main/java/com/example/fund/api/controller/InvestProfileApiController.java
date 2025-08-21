package com.example.fund.api.controller;

import java.time.LocalDate;

import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.api.dto.investTest.RiskQuestionListResponse;
import com.example.fund.api.dto.investTest.RiskResultView;
import com.example.fund.api.dto.investTest.RiskSubmitRequest;
import com.example.fund.api.service.InvestProfileApiService;
import com.example.fund.common.CurrentUid;
import com.example.fund.fund.dto.InvestTypeResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/risk-test")
@RequiredArgsConstructor
public class InvestProfileApiController {

    private final InvestProfileApiService investProfileApiService;

    @GetMapping("/questions")
    public RiskQuestionListResponse questions(@CurrentUid Integer uid, @AuthenticationPrincipal Jwt jwt) {
        System.out.println("claims=" + jwt.getClaims()); // uid 타입 확인
        return investProfileApiService.getQuestions(uid);
    }

    @PostMapping("/submit")
    public ResponseEntity<RiskResultView> submit(
            @CurrentUid Integer uid,
            @RequestBody @Valid RiskSubmitRequest request) {
        System.out.println(request);
        RiskResultView view = investProfileApiService.evaluateAndSave(uid, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(view);
    }

    @GetMapping("/result/latest")
    public RiskResultView latest(@CurrentUid Integer uid) {
        System.out.println(uid);
        System.out.println("Latest: " + investProfileApiService.getLatest(uid));
        return investProfileApiService.getLatest(uid);
    }

    @GetMapping("/results")
    public Page<RiskResultView> history(
            @CurrentUid Integer uid,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return investProfileApiService.getHistory(uid, page, size);
    }

    @GetMapping("/eligibility")
    public InvestEligibilityResponse eligibility(@CurrentUid Integer uid) {
        boolean analyzedToday = investProfileApiService.hasAnalyzedToday(uid);
        LocalDate nextDateKst = investProfileApiService.nextAvailableDateKst(uid);

        System.out.println("result: " + analyzedToday);
        System.out.println("nextDateKst: " + nextDateKst);
        return new InvestEligibilityResponse(
                !analyzedToday,
                analyzedToday ? "오늘은 이미 투자성향 분석을 완료하셨습니다." : null,
                nextDateKst.toString());
    }

    @PostMapping("/submit-legacy")
    public ResponseEntity<RiskResultView> submitLegacy(
            @CurrentUid Integer uid,
            @RequestBody java.util.Map<String, String> paramMap) {
        RiskResultView view = investProfileApiService.evaluateAndSaveLegacy(uid, paramMap);
        return ResponseEntity.status(HttpStatus.CREATED).body(view);
    }

    @GetMapping("/result/latest/summary")
    public InvestTypeResponse latestSummary(@CurrentUid Integer uid) {
        return investProfileApiService.getLatestSummary(uid);
    }

    public record InvestEligibilityResponse(
            boolean allowed, // 기존: 재분석 가능 여부
            String reason, // 기존: 메시지
            String nextAvailableAt // 추가: "2025-08-22" 같은 ISO-8601 날짜 문자열
    ) {
    }
}