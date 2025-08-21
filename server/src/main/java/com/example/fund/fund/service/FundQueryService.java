package com.example.fund.fund.service;

import com.example.fund.fund.dto.*;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.repository_fund.FundRepository;
import com.example.fund.fund.repository_fund.FundReturnRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.List;


@Service
@RequiredArgsConstructor
@Slf4j
public class FundQueryService {

    private final FundRepository fundRepository;
    private final FundReturnRepository fundReturnRepository;

    // 상품 상태 필터를 고정하고 싶으면 여기 상수로 관리
    private static final String PRODUCT_STATUS = "PUBLISHED"; // null 이면 상품 존재 여부만 체크

    /**
     * 리스트: 상품 테이블에 있는 펀드만
     */
    public ApiResponse<List<FundListResponseDTO>> getFunds(String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("fundName").ascending());

        Page<Fund> p = fundRepository.findAllHavingProduct(
                (keyword == null || keyword.isBlank()) ? null : keyword,
                PRODUCT_STATUS, // 필요 시 null 로 바꾸면 "상품존재"만 체크
                pageable
        );

        List<FundListResponseDTO> rows = p.getContent().stream().map(f -> {
            var r = fundReturnRepository
                    .findTopByFund_FundIdOrderByBaseDateDesc(f.getFundId())
                    .orElse(null);

            return FundListResponseDTO.builder()
                    .fundId(f.getFundId())
                    .fundName(f.getFundName())
                    .fundType(f.getFundType())
                    .fundDivision(f.getFundDivision())
                    .riskLevel(f.getRiskLevel())
                    .managementCompany(f.getManagementCompany())
                    .issueDate(f.getIssueDate())
                    .return1m(r == null || r.getReturn1m() == null ? null : r.getReturn1m().doubleValue())
                    .return3m(r == null || r.getReturn3m() == null ? null : r.getReturn3m().doubleValue())
                    .return12m(r == null || r.getReturn12m() == null ? null : r.getReturn12m().doubleValue())
                    .build();
        }).toList();

        return ApiResponse.success(rows, PaginationInfo.from(p));
    }
}
    /*// 컨트롤러에서 호출하는 실제 목록 메서드
    public ApiResponse<List<FundListResponseDTO>> getFunds(String keyword, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("fundName").ascending());

        Page<Fund> p = (keyword == null || keyword.isBlank())
                ? fundRepository.findAll(pageable)
                : fundRepository.findByFundNameContainingIgnoreCase(keyword, pageable);

        List<FundListResponseDTO> rows = p.getContent().stream().map(f -> {
            var r = fundReturnRepository
                    .findTopByFund_FundIdOrderByBaseDateDesc(f.getFundId())
                    .orElse(null);

            return FundListResponseDTO.builder()
                    .fundId(f.getFundId())
                    .fundName(f.getFundName())
                    .fundType(f.getFundType())
                    .fundDivision(f.getFundDivision())
                    .riskLevel(f.getRiskLevel())
                    .managementCompany(f.getManagementCompany())
                    .issueDate(f.getIssueDate())
                    .return1m(r == null || r.getReturn1m() == null ? null : r.getReturn1m().doubleValue())
                    .return3m(r == null || r.getReturn3m() == null ? null : r.getReturn3m().doubleValue())
                    .return12m(r == null || r.getReturn12m() == null ? null : r.getReturn12m().doubleValue())
                    .build();
        }).toList();

        return ApiResponse.success(rows, PaginationInfo.from(p));
    }*/
