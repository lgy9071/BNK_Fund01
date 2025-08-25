package com.example.fund.fund.service;

import com.example.fund.common.dto.ApiResponse;
import com.example.fund.fund.dto.*;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.repository_fund.FundRepository;
import com.example.fund.fund.repository_fund.FundReturnRepository;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class FundQueryService {

        private final FundRepository fundRepository;
        private final FundReturnRepository fundReturnRepository;
        private final InvestProfileResultRepository investProfileResultRepository;

        private static final String PRODUCT_STATUS = "PUBLISHED";

        /**
         * 모든 펀드 (상품이 등록된 것만)
         */
        public ApiResponse<List<FundListResponseDTO>> getFunds(String keyword, int page, int size) {
                Pageable pageable = PageRequest.of(page, size, Sort.by("fundName").ascending());

                Page<Fund> p = fundRepository.findAllHavingProduct(
                                (keyword == null || keyword.isBlank()) ? null : keyword,
                                PRODUCT_STATUS,
                                pageable);

                List<FundListResponseDTO> rows = mapToListDTO(p);
                return ApiResponse.success(rows, PaginationInfo.from(p));
        }

        /**
         * 내 투자성향 riskLevel 이하의 펀드만
         */
        public ApiResponse<List<FundListResponseDTO>> getFundsEligible(String keyword, int page, int size,
                        Integer uid) {
                var latest = investProfileResultRepository
                                .findTopByUser_UserIdOrderByAnalysisDateDesc(uid)
                                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "투자성향 결과가 없습니다."));

                // 사용자 투자성향: 1~5
                int userTier = latest.getType().getRiskLevel();

                // ✅ 투자성향 5면 6등급까지 허용, 나머지는 기존과 동일
                int allowedMaxRisk = (userTier >= 5) ? 6 : userTier;

                Pageable pageable = PageRequest.of(page, size, Sort.by("fundName").ascending());

                Page<Fund> p = fundRepository.findAllHavingProductWithMaxRisk(
                                (keyword == null || keyword.isBlank()) ? null : keyword,
                                PRODUCT_STATUS,
                                allowedMaxRisk, // ★ 여기만 변경
                                pageable);

                List<FundListResponseDTO> rows = mapToListDTO(p);
                return ApiResponse.success(rows, PaginationInfo.from(p));
        }

        private List<FundListResponseDTO> mapToListDTO(Page<Fund> p) {
                return p.getContent().stream().map(f -> {
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
                                        .return1m(r == null || r.getReturn1m() == null ? null
                                                        : r.getReturn1m().doubleValue())
                                        .return3m(r == null || r.getReturn3m() == null ? null
                                                        : r.getReturn3m().doubleValue())
                                        .return12m(r == null || r.getReturn12m() == null ? null
                                                        : r.getReturn12m().doubleValue())
                                        .build();
                }).toList();
        }
}
/*
 * // 컨트롤러에서 호출하는 실제 목록 메서드
 * public ApiResponse<List<FundListResponseDTO>> getFunds(String keyword, int
 * page, int size) {
 * Pageable pageable = PageRequest.of(page, size,
 * Sort.by("fundName").ascending());
 * 
 * Page<Fund> p = (keyword == null || keyword.isBlank())
 * ? fundRepository.findAll(pageable)
 * : fundRepository.findByFundNameContainingIgnoreCase(keyword, pageable);
 * 
 * List<FundListResponseDTO> rows = p.getContent().stream().map(f -> {
 * var r = fundReturnRepository
 * .findTopByFund_FundIdOrderByBaseDateDesc(f.getFundId())
 * .orElse(null);
 * 
 * return FundListResponseDTO.builder()
 * .fundId(f.getFundId())
 * .fundName(f.getFundName())
 * .fundType(f.getFundType())
 * .fundDivision(f.getFundDivision())
 * .riskLevel(f.getRiskLevel())
 * .managementCompany(f.getManagementCompany())
 * .issueDate(f.getIssueDate())
 * .return1m(r == null || r.getReturn1m() == null ? null :
 * r.getReturn1m().doubleValue())
 * .return3m(r == null || r.getReturn3m() == null ? null :
 * r.getReturn3m().doubleValue())
 * .return12m(r == null || r.getReturn12m() == null ? null :
 * r.getReturn12m().doubleValue())
 * .build();
 * }).toList();
 * 
 * return ApiResponse.success(rows, PaginationInfo.from(p));
 * }
 */
