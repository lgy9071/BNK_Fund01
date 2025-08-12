package com.example.ap.service.admin;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.example.ap.repository.admin.projection.FaqCategoryCount;
import com.example.ap.repository.fund.FaqCategoryMapRepository;
import com.example.ap.repository.fund.FaqRepository;
import com.example.common.entity.fund.Faq;
import com.example.common.entity.fund.FaqCategoryMap;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FaqAdminService {

    private final FaqRepository faqRepository;
    private final FaqCategoryMapRepository mapRepository;

    public List<Faq> findAll() {
        return faqRepository.findAll();
    }

    public void save(Faq faq) {
        faqRepository.save(faq);
    }

    public Faq findById(Integer id) {
        return faqRepository.findById(id).orElse(null);
    }

    public void update(Integer id, Faq newFaq) {
        Faq existing = faqRepository.findById(id).orElseThrow();
        existing.setQuestion(newFaq.getQuestion());
        existing.setAnswer(newFaq.getAnswer());
        faqRepository.save(existing);
    }

    public void delete(Integer id) {
        // 1) FAQ 엔티티 삭제
        faqRepository.deleteById(id);
        // 2) 매핑 테이블에서 동일 faqId 로 된 모든 레코드 삭제
        mapRepository.deleteByFaqId(id);
    }

    public List<Faq> findActiveFaqs() {
        return faqRepository.findByActiveTrue();
    }

    public Page<Faq> search(String keyword, Pageable pageable) {
        return faqRepository.searchActiveFaqs(keyword, pageable);
    }

    public Page<Faq> findAllWithPaging(Pageable pageable) {
        return faqRepository.findAll(pageable);
    }

    /* 전체 FAQ 건수 반환 */
    public long countAllFaqs() {
        return faqRepository.count();
    }

    /* 관리자 전용: FAQ 카테고리별 건수 집계 */
    public Map<String, Integer> getFaqCountsByCategory() {
        return mapRepository.countByCategory()
                .stream()
                .collect(Collectors.toMap(
                        FaqCategoryCount::getCategory,
                        c -> c.getCnt().intValue()  // Long → Integer 변환
                ));
    }

    /* 관리자 전용: FAQ에 카테고리 매핑 */
    public void mapCategory(Integer faqId, String category) {
        mapRepository.save(FaqCategoryMap.builder()
                .faqId(faqId)
                .category(category)
                .build());
    }
}
