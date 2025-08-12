package com.example.ap.util.jwt;

import org.springframework.data.domain.Page;
import org.springframework.stereotype.Component;

import com.example.common.dto.fund.PaginationInfo;

@Component
public class PaginationAssembler {
    public PaginationInfo from(Page<?> page) {
        int pageNumber1 = page.getNumber() + 1; // 1-base로 응답
        return PaginationInfo.builder()
            .page(pageNumber1)
            .limit(page.getSize())
            .total(page.getTotalElements())
            .totalPages(page.getTotalPages())
            .hasNext(page.hasNext())
            .hasPrev(page.hasPrevious())
            .currentItems(page.getNumberOfElements())
            .build();
    }
}
