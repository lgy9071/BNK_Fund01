package com.example.fund.fund.controller;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.common.CurrentUid;
import com.example.fund.fund.dto.review.CreateReviewRequest;
import com.example.fund.fund.dto.review.EligibilityResponse;
import com.example.fund.fund.dto.review.ReviewItem;
import com.example.fund.fund.dto.review.ReviewListResponse;
import com.example.fund.fund.dto.review.SummaryResponse;
import com.example.fund.fund.dto.review.SummaryStatus;
import com.example.fund.fund.dto.review.UpdateReviewRequest;
import com.example.fund.fund.entity_fund.FundReview;
import com.example.fund.fund.entity_fund.ReviewAiSummary;
import com.example.fund.fund.repository_fund.FundHoldingRepository;
import com.example.fund.fund.service.FundReviewService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;


@RestController
@RequiredArgsConstructor
@RequestMapping("/api/funds")
public class FundReviewApiController {
    private final FundReviewService reviewService;
    private final FundHoldingRepository fundHoldingRepository;

    /** 리뷰 작성 (JWT → @CurrentId) */
    @PostMapping("/{fundId}/reviews")
    public ResponseEntity<Long> create(@PathVariable String fundId,
                                       @RequestBody @Valid CreateReviewRequest req,
                                       @CurrentUid Integer userId) {
        Long id = reviewService.createReview(userId, fundId, req.getText());
        return ResponseEntity.ok(id);
    }

    /** 리뷰 수정 (DB 트리거가 1회 제한 강제) */
    @PutMapping("/{fundId}/reviews/{reviewId}")
    public ResponseEntity<Void> update(@PathVariable String fundId,
                                       @PathVariable Long reviewId,
                                       @RequestBody @Valid UpdateReviewRequest req,
                                       @CurrentUid Integer userId) {
        reviewService.updateReview(userId, fundId, reviewId, req.getText());
        return ResponseEntity.noContent().build();
    }

    /** 리뷰 삭제(소프트 삭제) */
    @DeleteMapping("/{fundId}/reviews/{reviewId}")
    public ResponseEntity<Void> delete(@PathVariable String fundId,
                                       @PathVariable Long reviewId,
                                       @CurrentUid Integer userId) {
        reviewService.deleteReview(userId, fundId, reviewId);
        return ResponseEntity.noContent().build();
    }

    /** 펀드별 리뷰 목록 (페이지네이션) */
    @GetMapping("/{fundId}/reviews")
    public ResponseEntity<ReviewListResponse> list(@PathVariable String fundId,
                                                   @RequestParam(defaultValue = "0") int page,
                                                   @RequestParam(defaultValue = "20") int size) {
        Page<FundReview> p = reviewService.listReviews(fundId, page, size);
        List<ReviewItem> items = p.map(r -> ReviewItem.builder()
                .reviewId(r.getReviewId())
                .userId(r.getUserId())
                .fundId(r.getFundId())
                .text(r.getReviewText())
                .createdAt(r.getCreatedAt())
                .editCount(r.getEditCount())
                .build()
        ).toList();

        return ResponseEntity.ok(
                ReviewListResponse.builder()
                        .fundId(fundId)
                        .page(page)
                        .size(size)
                        .total(p.getTotalElements())
                        .items(items)
                        .build()
        );
    }

    /**
     * 요약 조회(필요 시 LLM으로 생성/갱신)
     * - 활성 리뷰 < 5 → INSUFFICIENT
     * - >= 5 → 캐시가 없거나(또는 30분 경과/개수 변화)일 경우 LLM 호출→업서트 후 반환
     */
    @GetMapping("/{fundId}/review-summary")
    public ResponseEntity<SummaryResponse> summary(@PathVariable String fundId) {
        long activeCnt = reviewService.listReviews(fundId, 0, 1).getTotalElements();
        if (activeCnt < 5) {
            return ResponseEntity.ok(
                    SummaryResponse.builder()
                            .status(SummaryStatus.INSUFFICIENT)
                            .fundId(fundId)
                            .summaryText(null)
                            .lastGeneratedAt(null)
                            .reviewCountAtGen(null)
                            .activeReviewCount(activeCnt)
                            .build()
            );
        }

        ReviewAiSummary s = reviewService.getOrRefreshSummary(fundId);
        return ResponseEntity.ok(
                SummaryResponse.builder()
                        .status(SummaryStatus.OK)
                        .fundId(fundId)
                        .summaryText(s != null ? s.getSummaryText() : null)
                        .lastGeneratedAt(s != null ? s.getLastGeneratedAt() : null)
                        .reviewCountAtGen(s != null ? s.getReviewCountAtGen() : null)
                        .activeReviewCount(activeCnt)
                        .build()
        );
    }

    /**
     * (선택) 리뷰 작성 가능 여부 — 메뉴 진입 전에 가볍게 확인
     *  - 간단 버전: “이미 본인 리뷰가 있는지”만 체크
     *  - 보유 여부까지 엄격히 보려면 Service에 별도 메서드 추가해서 FUND_HOLDING까지 함께 검사하세요.
     */
    @GetMapping("/{fundId}/reviews/eligibility")
    public ResponseEntity<EligibilityResponse> eligibility(@PathVariable String fundId,
                                                           @CurrentUid Integer userId) {
        // 간단 체크: 현재 페이지 1개 가져와서 본인 리뷰 존재 여부 확인
        boolean alreadyWritten = reviewService
                .listReviews(fundId, 0, 100)
                .stream()
                .anyMatch(r -> r.getUserId().equals(userId));

        return ResponseEntity.ok(
                EligibilityResponse.builder()
                        .canWrite(!alreadyWritten)
                        .build()
        );
    }

    @GetMapping("/holdings")
    public List<MyHoldingDto> getHoldings(@CurrentUid Integer userId) {
        return fundHoldingRepository.findByUser_UserId(userId).stream()
            .map(h -> new MyHoldingDto(
                h.getFund().getFundId(),       // Fund 엔티티의 fundId
                h.getFund().getFundName(),     // Fund 엔티티의 fundName (Fund 엔티티에 있는 필드 확인)
                h.getQuantity(),
                h.getAvgPrice(),
                h.getJoinedAt()
            ))
            .toList();
    }

    // DTO 정의
    public record MyHoldingDto(
    String fundId,
    String fundName,
    int quantity,
    int avgPrice,
    LocalDateTime joinedAt
) {}

}
