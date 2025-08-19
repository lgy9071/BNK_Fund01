package com.example.fund.api.controller;

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
        return new InvestEligibilityResponse(
                investProfileApiService.hasAnalyzedToday(uid) ? false : true,
                investProfileApiService.hasAnalyzedToday(uid) ? "오늘은 이미 투자성향 분석을 완료하셨습니다." : null);
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

    public record InvestEligibilityResponse(boolean allowed, String reason) {
    }
}
