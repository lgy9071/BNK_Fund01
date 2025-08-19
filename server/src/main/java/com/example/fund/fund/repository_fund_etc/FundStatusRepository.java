package com.example.fund.fund.repository_fund_etc;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.fund.entity_fund_etc.FundStatus;

public interface FundStatusRepository extends JpaRepository<FundStatus, Integer> {
	
	// 이전글
    FundStatus findTopByStatusIdLessThanOrderByStatusIdDesc(Integer id);

    // 다음글
    FundStatus findTopByStatusIdGreaterThanOrderByStatusIdAsc(Integer id);
    
    Page<FundStatus> findByTitleContainingIgnoreCaseOrContentContainingIgnoreCaseOrCategoryContainingIgnoreCase(String title, String content, String category, Pageable pageable);
}
