package com.example.ap.repository.fund;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.example.ap.repository.admin.projection.FaqCategoryCount;
import com.example.common.entity.fund.FaqCategoryMap;
import com.example.common.entity.fund.FaqCategoryMapId;

@Repository
public interface FaqCategoryMapRepository extends JpaRepository<FaqCategoryMap, FaqCategoryMapId> {

    @Query("""
      SELECT m.category AS category,
             COUNT(m)    AS cnt
      FROM FaqCategoryMap m
      GROUP BY m.category
    """)
    List<FaqCategoryCount> countByCategory();

    /* faqId 로 매핑된 모든 카테고리 레코드 삭제 */
    void deleteByFaqId(Integer faqId);
}