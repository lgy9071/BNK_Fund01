package com.example.fund.fund.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.domain.Page;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PaginationInfo {
    private int page;          // 0-based
    private int limit;
    private long total;
    private int totalPages;
    private boolean hasNext;
    private boolean hasPrev;
    private int currentItems;

    public static PaginationInfo from(Page<?> page) {
        int cur = page.getNumber();      // 0-based
        int totalPages = page.getTotalPages();
        return PaginationInfo.builder()
                .page(cur)
                .limit(page.getSize())
                .total(page.getTotalElements())
                .totalPages(totalPages)
                .hasNext(cur < totalPages - 1) // 마지막 페이지면 false
                .hasPrev(cur > 0)              // 첫 페이지면 false
                .currentItems(page.getNumberOfElements())
                .build();
    }
}