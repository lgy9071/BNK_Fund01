package com.example.fund.fund.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.example.fund.fund.entity_fund_etc.FundStatus;
import com.example.fund.fund.repository_fund_etc.FundStatusRepository;

import jakarta.persistence.EntityNotFoundException;
import jakarta.transaction.Transactional;

@Service
public class FundStatusService {
	
	@Autowired
	FundStatusRepository fundStatusRepository;
	
	public List<FundStatus> statusList(){
		return fundStatusRepository.findAll();
	}

    public FundStatus getPrevStatus(Integer id) {
        return fundStatusRepository.findTopByStatusIdLessThanOrderByStatusIdDesc(id);
    }

    public FundStatus getNextStatus(Integer id) {
        return fundStatusRepository.findTopByStatusIdGreaterThanOrderByStatusIdAsc(id);
    }
    
    @Transactional
    public void incrementViewCount(Integer id) {
		FundStatus fund = fundStatusRepository.findById(id)
				.orElseThrow(() -> new EntityNotFoundException("해당 글이 존재하지 않습니다."));
		fund.setViewCount(fund.getViewCount() + 1);
	}
	
	public FundStatus getDetail(Integer id) {
	    return fundStatusRepository.findById(id)
	        .orElseThrow(() -> new IllegalArgumentException("해당 글이 존재하지 않습니다."));
	}
	
	public Page<FundStatus> getPagedStatusListByKeyword(int page, int size, String keyword){
		Pageable pageable = PageRequest.of(page, size, Sort.by("regDate").descending());
		return fundStatusRepository.findByTitleContainingIgnoreCaseOrContentContainingIgnoreCaseOrCategoryContainingIgnoreCase(
				keyword, keyword, keyword, pageable);
	}
}
