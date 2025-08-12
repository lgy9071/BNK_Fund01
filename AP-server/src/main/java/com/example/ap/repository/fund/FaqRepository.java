package com.example.ap.repository.fund;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.ap.repository.admin.projection.FaqCategoryCount;
import com.example.common.entity.fund.Faq;

public interface FaqRepository extends JpaRepository<Faq, Integer> {
    List<Faq> findByActiveTrue();  // 활성화된 FAQ만 조회

	// 제목 또는 답변에 키워드가 포함되어있고 활성화되어있는 fAQ 검색
	@Query("SELECT f FROM Faq f WHERE f.active = true AND (f.question LIKE %:keyword% OR f.answer LIKE %:keyword%)")
	Page<Faq> searchActiveFaqs(@Param("keyword") String keyword, Pageable pageable);

	/** 카테고리별 FAQ 건수 집계 */
	@Query("""
      SELECT m.category AS category,
             COUNT(m)    AS cnt
      FROM FaqCategoryMap m
      GROUP BY m.category
    """)
	List<FaqCategoryCount> countByCategory();
}
