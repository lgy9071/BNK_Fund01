package com.example.fund.fund.repository_fund_etc;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.fund.entity_fund_etc.FundStatus;

public interface FundStatusRepository extends JpaRepository<FundStatus, Integer> {

    // 이전글
    FundStatus findTopByStatusIdLessThanOrderByStatusIdDesc(Integer id);

    // 다음글
    FundStatus findTopByStatusIdGreaterThanOrderByStatusIdAsc(Integer id);

    Page<FundStatus> findByTitleContainingIgnoreCaseOrContentContainingIgnoreCaseOrCategoryContainingIgnoreCase(
            String title, String content, String category, Pageable pageable);

    @Query("""
            SELECT f FROM FundStatus f
            WHERE (:q IS NULL OR :q = '' OR LOWER(f.title) LIKE LOWER(CONCAT('%', :q, '%'))
                                  OR LOWER(f.content) LIKE LOWER(CONCAT('%', :q, '%')))
              AND (:category IS NULL OR :category = '' OR f.category = :category)
            """)
    Page<FundStatus> search(@Param("q") String q,
            @Param("category") String category,
            Pageable pageable);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE FundStatus f SET f.viewCount = f.viewCount + 1 WHERE f.statusId = :id")
    int incrView(@Param("id") Integer id);
}
