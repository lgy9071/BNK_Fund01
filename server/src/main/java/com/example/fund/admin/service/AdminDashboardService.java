package com.example.fund.admin.service;

import com.example.fund.admin.faq.repository.projection.FaqCategoryCount;
import com.example.fund.faq.repository.FaqRepository;
import com.example.fund.qna.entity.Qna;
import com.example.fund.qna.repository.QnaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.ui.Model;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    // FAQ 데이터 접근용 Repository
    private final FaqRepository faqRepo;

    // QnA 데이터 접근용 Repository
    private final QnaRepository qnaRepo;

    /**
     * 최고 관리자(super) 대시보드에 필요한 통계 데이터를
     * Model 객체에 세팅하는 전용 메서드
     *
     * @param model 컨트롤러에서 전달받은 Model 객체
     */
    public void populateSuperMetrics(Model model) {

        /* =====================================================
         * 1) FAQ 카테고리별 집계
         * ===================================================== */

        // FAQ 카테고리별 건수를 Projection으로 조회
        List<FaqCategoryCount> cats = faqRepo.countByCategory();

        // Projection 결과를 Map<카테고리명, 건수> 형태로 변환
        Map<String, Long> faqCatMap = cats.stream()
                .collect(Collectors.toMap(
                        FaqCategoryCount::getCategory,
                        FaqCategoryCount::getCnt
                ));

        // 대시보드에서 카테고리별 FAQ 분포 표시용
        model.addAttribute("faqCategoryCounts", faqCatMap);

        /* =====================================================
         * 2) 전체 미답변 문의 건수
         * ===================================================== */

        // 상태(status)가 null인 QnA = 미답변 문의
        long unAnswered = qnaRepo.countByStatusIsNull();

        // 전체 미답변 개수 표시용
        model.addAttribute("unansweredCount", unAnswered);

        /* =====================================================
         * 3) 24시간 이상 미답변 문의 건수
         * ===================================================== */

        // 전체 QnA 중
        //  - 상태가 null(미답변)
        //  - 등록 후 24시간 이상 경과한 문의만 필터링
        List<Qna> allUn = qnaRepo.findAll().stream()
                .filter(q ->
                        q.getStatus() == null &&
                                Duration.between(
                                        q.getRegDate(),
                                        LocalDateTime.now()
                                ).toHours() >= 24
                )
                .collect(Collectors.toList());

        // 장기 미처리 문의 개수
        model.addAttribute("longPendingCount", allUn.size());

        /* =====================================================
         * 4) 최장 대기 문의 & 대기 시간
         * ===================================================== */

        // 가장 오래된 미답변 문의 1건 조회
        Optional<Qna> oldest =
                qnaRepo.findFirstByStatusIsNullOrderByRegDateAsc();

        if (oldest.isPresent()) {
            Qna o = oldest.get();

            // 현재 시각 기준 대기 시간(시간 단위) 계산
            long hrs = Duration.between(
                    o.getRegDate(),
                    LocalDateTime.now()
            ).toHours();

            // 가장 오래된 미답변 문의 객체
            model.addAttribute("oldestUnanswered", o);

            // 대기 시간 문자열 형태로 전달
            model.addAttribute("oldestDuration", hrs + "시간");

        } else {
            // 미답변 문의가 없을 경우 기본값 세팅
            model.addAttribute("oldestDuration", "0시간");
        }
    }
}
