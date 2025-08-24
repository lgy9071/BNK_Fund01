package com.example.fund.fund.service;

import com.example.fund.common.dto.ApiResponse;
import com.example.fund.fund.dto.FundDetailResponseDTO;
import com.example.fund.fund.dto.FundProductDocDto;
import com.example.fund.fund.dto.FundProductView;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundDocument;
import com.example.fund.fund.repository_fund.FundRepository;
import com.example.fund.fund.repository_fund.FundStatusDailyRepository;
import com.example.fund.fund.repository_fund.FundReturnRepository;
import com.example.fund.fund.repository_fund.FundAssetSummaryRepository;
import com.example.fund.fund.repository_fund.FundFeeInfoRepository;
import com.example.fund.fund.repository_fund.FundProductRepository;
import com.example.fund.fund.repository_fund.FundDocumentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class FundDetailService {

    private final FundRepository fundRepository;
    private final FundStatusDailyRepository fundStatusDailyRepository;
    private final FundReturnRepository fundReturnRepository;
    private final FundAssetSummaryRepository fundAssetSummaryRepository;
    private final FundFeeInfoRepository fundFeeInfoRepository;

    // 상품/문서
    private final FundProductRepository fundProductRepository;
    private final FundDocumentRepository fundDocumentRepository;

    public ApiResponse<FundDetailResponseDTO> getFundDetail(String fundId) {
        Fund f = fundRepository.findByFundId(fundId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "펀드를 찾을 수 없습니다. fundId=" + fundId));

        // 1) 제품 로드 전용 로그
        var pOpt = fundProductRepository.findTopByFund_FundIdOrderByProductIdDesc(fundId);
        if (pOpt.isEmpty()) {
            log.warn("NO PRODUCT row for fundId={}", fundId);
        } else {
            var p = pOpt.get();
            log.info("productId={}, status={}, summaryDocId={}, prospectusDocId={}, termsDocId={}",
                    p.getProductId(), p.getStatus(), p.getSummaryDocId(), p.getProspectusDocId(), p.getTermsDocId());
        }

        var latestStatus = fundStatusDailyRepository.findTopByFund_FundIdOrderByBaseDateDesc(fundId).orElse(null);
        var latestReturn = fundReturnRepository.findTopByFund_FundIdOrderByBaseDateDesc(fundId).orElse(null);
        var latestAsset  = fundAssetSummaryRepository.findTopByFund_FundIdOrderByBaseDateDesc(fundId).orElse(null);
        var fee          = fundFeeInfoRepository.findTopByFund_FundId(fundId).orElse(null);

        // ── 상품/문서 조회 (있으면 productView에 담고 DTO에 포함)
        FundProductView productView = fundProductRepository
                .findTopByFund_FundIdOrderByProductIdDesc(fundId)
                .map(p -> {
                    List<FundProductDocDto> docs = new ArrayList<>();
                    addDoc(docs, p.getSummaryDocId(),    "SUMMARY");
                    addDoc(docs, p.getProspectusDocId(), "PROSPECTUS");
                    addDoc(docs, p.getTermsDocId(),      "TERMS");
                    log.info("built docs size={}", docs.size());   // 2) 최종 docs 개수 로그
                    return new FundProductView(p.getProductId(), p.getStatus(), docs);
                })
                .orElse(null);

        FundDetailResponseDTO dto = FundDetailResponseDTO.builder()
                .fundId(f.getFundId())
                .fundName(f.getFundName())
                .fundType(f.getFundType())
                .investmentRegion(f.getInvestmentRegion())
                .riskLevel(f.getRiskLevel())
                .managementCompany(f.getManagementCompany())
                .totalExpenseRatio(fee == null ? null : fee.getTer())
                .nav(latestStatus == null ? null : latestStatus.getNavPrice())
                .aum(
                        latestStatus == null || latestStatus.getNavTotal() == null
                                ? null
                                : latestStatus.getNavTotal().intValue()   // DTO가 Integer라서 intValue()
                )
                .return1m(latestReturn == null ? null : latestReturn.getReturn1m())
                .return3m(latestReturn == null ? null : latestReturn.getReturn3m())
                .return6m(latestReturn == null ? null : latestReturn.getReturn6m())
                .return12m(latestReturn == null ? null : latestReturn.getReturn12m())
                .domesticStock(latestAsset == null ? null : latestAsset.getStockRatio())
                .domesticBond(latestAsset == null ? null : latestAsset.getBondRatio())
                .liquidity(latestAsset == null ? null : latestAsset.getCashRatio())
                .product(productView) // 여기로 product + docs 내려감
                .build();

        return ApiResponse.success(dto);
    }

    /**
     * FundDocument에서 파일명/경로를 읽어 정적 URL로 만들어 docs에 추가
     * - DB에 filePath가 있으면 그대로 사용(앞에 '/' 없으면 붙임)
     * - 없으면 fileName을 사용해서 /fund_document/{encodedFileName} 생성
     */
    private void addDoc(java.util.List<FundProductDocDto> out, Long docId, String type) {
        if (docId == null) return;

        FundDocument d = fundDocumentRepository.findById(docId).orElse(null);
        String fileName = (d != null) ? d.getFileName() : null;
        String filePath = (d != null) ? d.getFilePath() : null;

        String path = null;

        // filePath가 있어도 '디렉터리'만 들어온 경우 파일명 붙여 보정
        if (filePath != null && !filePath.isBlank()) {
            String p = filePath.startsWith("/") ? filePath.substring(1) : filePath; // 선행 '/' 제거
            boolean looksLikeDir = !p.contains(".") || p.endsWith("/");
            if (looksLikeDir) {
                if (fileName != null && !fileName.isBlank()) {
                    String encoded = org.springframework.web.util.UriUtils
                            .encodePath(fileName, java.nio.charset.StandardCharsets.UTF_8);
                    path = "/" + (p.endsWith("/") ? p : (p + "/")) + encoded;
                }
            } else {
                path = "/" + p; // 이미 파일까지 포함되어 있던 경우
            }
        }

        // filePath가 없으면 fileName으로 /fund_document/{encodedFileName} 생성
        if (path == null && fileName != null && !fileName.isBlank()) {
            String encoded = org.springframework.web.util.UriUtils
                    .encodePath(fileName, java.nio.charset.StandardCharsets.UTF_8);
            path = "/fund_document/" + encoded;
        }

        out.add(new FundProductDocDto(docId, type, fileName, path));
    }
}