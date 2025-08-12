package com.example.ap.service.admin;


import java.time.Duration;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.ui.Model;

import com.example.ap.repository.admin.projection.FaqCategoryCount;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {
    private final FaqRepository faqRepo;
    private final QnaRepository qnaRepo;

    public void populateSuperMetrics(Model model) {
        // 1) FAQ 카테고리별 상위 3개
        List<FaqCategoryCount> cats = faqRepo.countByCategory();
        Map<String,Long> faqCatMap = cats.stream()
                .collect(Collectors.toMap(FaqCategoryCount::getCategory, FaqCategoryCount::getCnt));
        model.addAttribute("faqCategoryCounts", faqCatMap);

        // 2) 전체 미답변 건수
        long unAnswered = qnaRepo.countByStatusIsNull();
        model.addAttribute("unansweredCount", unAnswered);

        // 3) 24시간 이상 미답변 건수
        List<Qna> allUn = qnaRepo.findAll().stream()
                .filter(q -> q.getStatus() == null
                        && Duration.between(q.getRegDate(), LocalDateTime.now()).toHours() >= 24)
                .collect(Collectors.toList());
        model.addAttribute("longPendingCount", allUn.size());

        // 4) 최장 대기 문의 & 대기시간
        Optional<Qna> oldest = qnaRepo.findFirstByStatusIsNullOrderByRegDateAsc();
        if (oldest.isPresent()) {
            Qna o = oldest.get();
            long hrs = Duration.between(o.getRegDate(), LocalDateTime.now()).toHours();
            model.addAttribute("oldestUnanswered", o);
            model.addAttribute("oldestDuration", hrs + "시간");
        } else {
            model.addAttribute("oldestDuration", "0시간");
        }
    }
}
