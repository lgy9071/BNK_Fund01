package com.example.ap.repository.fund;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.FundStatus;

public interface FundStatusRepository extends JpaRepository<FundStatus, Integer> {
	
	// 이전글
    FundStatus findTopByStatusIdLessThanOrderByStatusIdDesc(Integer id);

    // 다음글
    FundStatus findTopByStatusIdGreaterThanOrderByStatusIdAsc(Integer id);
    
    Page<FundStatus> findByTitleContainingIgnoreCaseOrContentContainingIgnoreCaseOrCategoryContainingIgnoreCase(String title, String content, String category, Pageable pageable);
}
