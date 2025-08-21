package com.example.fund.api.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.api.dto.fundStatus.FundStatusDetailDto;
import com.example.fund.api.dto.fundStatus.FundStatusListItemDto;
import com.example.fund.api.dto.fundStatus.PageResponse;
import com.example.fund.api.service.FundStatusApiService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/fund-status")
@RequiredArgsConstructor
public class FundStatusApiController {

    private final FundStatusApiService service;

    // 목록: 검색(q), 카테고리(category), 최신순(서버에서 정렬), 페이지네이션
    @GetMapping
    public PageResponse<FundStatusListItemDto> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String category,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return service.list(q, category, page, size);
    }

    // 상세: 조회수 증가 포함
    @GetMapping("/{id}")
    public FundStatusDetailDto detail(@PathVariable Integer id) {
        return service.detailAndIncreaseView(id);
    }
}