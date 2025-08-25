package com.example.fund.fund.service;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.util.List;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.fund.entity_fund.FundReview;
import com.example.fund.fund.entity_fund.ReviewAiSummary;
import com.example.fund.fund.repository_fund.FundHoldingRepository;
import com.example.fund.fund.repository_fund.FundReviewRepository;
import com.example.fund.fund.repository_fund.ReviewAiSummaryRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundReviewService {
    private final FundReviewRepository reviewRepo;
    private final ReviewAiSummaryRepository summaryRepo;
    private final FundHoldingRepository holdingRepo;

    // ★ CompareAiApiService와 동일한 방식으로 주입되는 Spring AI 클라이언트
    private final ChatClient chatClient;

    private static final int MIN_REVIEWS_TO_SUMMARIZE = 5;
    private static final Duration REFRESH_COOLTIME = Duration.ofMinutes(30);

    // ===== 리뷰 작성 =====
    @Transactional
    public Long createReview(Integer userId, String fundId, String text) {
        if (text == null || text.isBlank() || text.length() > 100) {
            throw new IllegalArgumentException("리뷰는 1~100자여야 합니다.");
        }
        if (holdingRepo.canReview(userId, fundId) == 0) {
            throw new IllegalStateException("보유중인 펀드가 아니어서 리뷰를 작성할 수 없습니다.");
        }
        reviewRepo.findActiveByFundIdAndUserId(fundId, userId).ifPresent(r -> {
            throw new IllegalStateException("이미 이 펀드에 리뷰를 작성했습니다.");
        });

        FundReview r = FundReview.builder()
                .fundId(fundId)
                .userId(userId)
                .reviewText(text)
                .build();
        reviewRepo.save(r);
        return r.getReviewId();
    }

    // ===== 리뷰 수정 (DB 트리거가 1회 제한 강제) =====
    @Transactional
    public void updateReview(Integer userId, String fundId, Long reviewId, String newText) {
        if (newText == null || newText.isBlank() || newText.length() > 100) {
            throw new IllegalArgumentException("리뷰는 1~100자여야 합니다.");
        }
        FundReview r = reviewRepo.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다."));
        if (!r.getUserId().equals(userId) || !r.getFundId().equals(fundId)) {
            throw new IllegalStateException("본인 리뷰만 수정할 수 있습니다.");
        }
        if (r.getDeletedAt() != null) {
            throw new IllegalStateException("삭제된 리뷰는 수정할 수 없습니다.");
        }
        r.setReviewText(newText);
        r.setUpdatedAt(OffsetDateTime.now());
        reviewRepo.save(r);
    }

    // ===== 리뷰 삭제(소프트) =====
    @Transactional
    public void deleteReview(Integer userId, String fundId, Long reviewId) {
        FundReview r = reviewRepo.findById(reviewId)
                .orElseThrow(() -> new IllegalArgumentException("리뷰를 찾을 수 없습니다."));
        if (!r.getUserId().equals(userId) || !r.getFundId().equals(fundId)) {
            throw new IllegalStateException("본인 리뷰만 삭제할 수 있습니다.");
        }
        if (r.getDeletedAt() == null) {
            r.setDeletedAt(OffsetDateTime.now());
            reviewRepo.save(r);
        }
    }

    // ===== 리뷰 목록 =====
    @Transactional(readOnly = true)
    public Page<FundReview> listReviews(String fundId, int page, int size) {
        return reviewRepo.findActiveByFundId(fundId, PageRequest.of(page, size));
    }

    // ===== 요약 조회(필요 시 LLM으로 생성/갱신) =====
    @Transactional
    public ReviewAiSummary getOrRefreshSummary(String fundId) {
        long activeCnt = reviewRepo.countActiveByFundId(fundId);
        if (activeCnt < MIN_REVIEWS_TO_SUMMARIZE) {
            // 부족하면 생성/갱신 없이 현재 캐시만 반환(없을 수도 있음)
            return summaryRepo.findByFundId(fundId).orElse(null);
        }

        var now = OffsetDateTime.now();
        var existingOpt = summaryRepo.findByFundId(fundId);

        boolean needRefresh = existingOpt.isEmpty();
        if (existingOpt.isPresent()) {
            var ex = existingOpt.get();
            boolean byTime  = Duration.between(ex.getLastGeneratedAt(), now).compareTo(REFRESH_COOLTIME) >= 0;
            boolean byCount = ex.getReviewCountAtGen() == null || ex.getReviewCountAtGen() != activeCnt;
            needRefresh = byTime || byCount;
        }

        if (needRefresh) {
            // 최근 리뷰 N개 텍스트만 수집 (너무 길어지지 않게 100개 한도)
            List<String> reviews = reviewRepo.findActiveByFundId(fundId, PageRequest.of(0, 100))
                    .map(FundReview::getReviewText).toList();

            // ★ LLM 호출 (CompareAiApiService 패턴 그대로)
            String prompt = buildSummaryPrompt(fundId, reviews);
            String raw    = callLlm(prompt);
            String clean  = extractPureText(raw); // 코드펜스/군더더기 제거
            if (clean == null || clean.isBlank()) {
                clean = "요약을 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.";
            }

            ReviewAiSummary target = existingOpt.orElseGet(ReviewAiSummary::new);
            target.setFundId(fundId);
            target.setSummaryText(clean);
            target.setLastGeneratedAt(now);
            target.setReviewCountAtGen((int) activeCnt);
            target.setModelProvider("spring-ai");
            target.setModelName("chat-client"); // 원하면 실제 모델명 주입

            summaryRepo.save(target); // INSERT or UPDATE
        }

        return summaryRepo.findByFundId(fundId).orElse(null);
    }

    // ====== 프롬프트/LLM 유틸 (CompareAiApiService 스타일) ======

    /** 리뷰 요약 프롬프트 (순수 텍스트 반환 지시) */
    private String buildSummaryPrompt(String fundId, List<String> reviews) {
        StringBuilder sb = new StringBuilder();
        sb.append("당신은 한국어로 답변하는 펀드 리뷰 요약가입니다.\n")
          .append("아래는 특정 펀드(").append(fundId).append(")에 대한 사용자 '한줄평' 목록입니다.\n")
          .append("핵심 의견을 겹치지 않게 묶어 **최대 세문장** 으로 간결히 요약하세요.\n")
          .append("사실 기반으로, 과도한 확신 표현은 피하고, 과거 수익률 불보장 고지는 포함하지 않아도 됩니다.\n")
          .append("마크다운/코드블록/장식 없이 순수 텍스트만 출력하세요.\n\n");

        if (reviews.isEmpty()) {
            sb.append("리뷰가 없습니다.\n");
        } else {
            sb.append("리뷰 목록:\n");
            int idx = 1;
            for (String r : reviews) {
                // 너무 긴 리뷰는 자르기 (LLM 토큰 과다 방지)
                String cut = r == null ? "" : (r.length() > 200 ? r.substring(0, 200) + "…" : r);
                sb.append(idx++).append(". ").append(cut).append("\n");
            }
        }
        sb.append("\n출력: 순수 요약 텍스트");
        return sb.toString();
    }

    /** Spring AI ChatClient 호출 */
    private String callLlm(String msg) {
        return chatClient.prompt().user(msg).call().content();
    }

    /** ```json/``` 코드펜스/스마트따옴표 제거 → 순수 텍스트 */
    private String extractPureText(String raw) {
        if (raw == null) return null;
        String s = raw.trim();
        s = s.replaceAll("(?s)```json\\s*(.*?)\\s*```", "$1");
        s = s.replaceAll("(?s)```\\s*(.*?)\\s*```", "$1");
        s = s.replace('“','"').replace('”','"').replace('’','\'').replace('‘','\'');
        return s.trim();
    }
}
