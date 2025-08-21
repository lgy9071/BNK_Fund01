package com.example.fund.api.service;

import java.util.stream.Collectors;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.api.dto.fundStatus.FundStatusDetailDto;
import com.example.fund.api.dto.fundStatus.FundStatusListItemDto;
import com.example.fund.api.dto.fundStatus.PageResponse;
import com.example.fund.fund.entity_fund_etc.FundStatus;
import com.example.fund.fund.repository_fund_etc.FundStatusRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundStatusApiService {
    private final FundStatusRepository repo;

    @Transactional(readOnly = true)
    public PageResponse<FundStatusListItemDto> list(String q, String category, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "regDate"));
        Page<FundStatus> result = repo.search(q, category, pageable);

        var content = result.getContent().stream().map(f -> new FundStatusListItemDto(
                f.getStatusId(),
                f.getCategory(),
                f.getTitle(),
                preview(f.getContent()),
                f.getViewCount(),
                f.getRegDate())).collect(Collectors.toList());

        return new PageResponse<>(content, result.getNumber(), result.getSize(),
                result.getTotalElements(), result.isLast());
    }

    private String preview(String content) {
        if (content == null)
            return "";
        return content.length() <= 120 ? content : content.substring(0, 120) + " …";
    }

    @Transactional
    public FundStatusDetailDto detailAndIncreaseView(Integer id) {
        // 1) 조회수 증가
        repo.incrView(id);
        // 2) 상세 조회
        FundStatus f = repo.findById(id).orElseThrow();
        return new FundStatusDetailDto(
                f.getStatusId(), f.getCategory(), f.getTitle(), f.getContent(),
                f.getViewCount(), f.getRegDate(), f.getModDate());
    }

}
