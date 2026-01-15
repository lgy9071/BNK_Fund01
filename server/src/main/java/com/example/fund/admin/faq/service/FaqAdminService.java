package com.example.fund.admin.faq.service;

import com.example.fund.admin.faq.entity.FaqCategoryMap;
import com.example.fund.admin.faq.entity.FaqCategoryMapId;
import com.example.fund.admin.faq.repository.FaqCategoryMapRepository;
import com.example.fund.admin.faq.repository.projection.FaqCategoryCount;
import com.example.fund.faq.entity.Faq;
import com.example.fund.faq.repository.FaqRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FaqAdminService {

    private final FaqRepository faqRepository;
    private final FaqCategoryMapRepository mapRepository;

    // 전체 FAQ 조회
    public List<Faq> findAll() {
        return faqRepository.findAll();
    }

    // FAQ 저장 (등록 / 수정 공용)
    public void save(Faq faq) {
        faqRepository.save(faq);
    }

    // ID로 FAQ 조회
    public Faq findById(Integer id) {
        return faqRepository.findById(id).orElse(null);
    }

    // FAQ 수정 (기본 필드만)
    public void update(Integer id, Faq newFaq) {
        Faq existing = faqRepository.findById(id).orElseThrow();
        existing.setQuestion(newFaq.getQuestion());
        existing.setAnswer(newFaq.getAnswer());
        faqRepository.save(existing);
    }

    /**
     * FAQ 삭제
     * 1) FAQ 테이블 삭제
     * 2) FAQ-카테고리 매핑 테이블 삭제
     */
    public void delete(Integer id) {
        faqRepository.deleteById(id);
        mapRepository.deleteByFaqId(id);
    }

    // 활성화된 FAQ만 조회 (사용자용)
    public List<Faq> findActiveFaqs() {
        return faqRepository.findByActiveTrue();
    }

    // FAQ 검색 + 페이징
    public Page<Faq> search(String keyword, Pageable pageable) {
        return faqRepository.searchActiveFaqs(keyword, pageable);
    }

    // 전체 FAQ 페이징 조회
    public Page<Faq> findAllWithPaging(Pageable pageable) {
        return faqRepository.findAll(pageable);
    }

    // 전체 FAQ 개수
    public long countAllFaqs() {
        return faqRepository.count();
    }

    /**
     * 카테고리별 FAQ 개수 반환
     */
    public Map<String, Integer> getFaqCountsByCategory() {
        return mapRepository.countByCategory()
                .stream()
                .collect(Collectors.toMap(
                        FaqCategoryCount::getCategory,
                        c -> c.getCnt().intValue()
                ));
    }

    /**
     * FAQ와 카테고리 매핑 저장
     */
    public void mapCategory(Integer faqId, String category) {
        mapRepository.save(FaqCategoryMap.builder()
                .faqId(faqId)
                .category(category)
                .build());
    }
}
