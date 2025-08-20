package com.example.fund.fund.service;

import com.example.fund.fund.dto.ApiResponse;
import com.example.fund.fund.dto.FundDetailResponseDTO;
import com.example.fund.fund.dto.FundProductDocDto;
import com.example.fund.fund.dto.FundProductView;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.entity_fund.FundDocument;
import com.example.fund.fund.repository_fund.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

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

        // ⬇️ 상품 없으면 404 (status 필터까지 걸고 싶으면 equalsIgnoreCase로 체크)
        fundProductRepository.findTopByFund_FundIdOrderByProductIdDesc(fundId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "상품이 등록된 펀드만 조회 가능합니다."));

        var latestStatus = fundStatusDailyRepository.findTopByFund_FundIdOrderByBaseDateDesc(fundId).orElse(null);
        var latestReturn = fundReturnRepository.findTopByFund_FundIdOrderByBaseDateDesc(fundId).orElse(null);
        var latestAsset  = fundAssetSummaryRepository.findTopByFund_FundIdOrderByBaseDateDesc(fundId).orElse(null);
        var fee          = fundFeeInfoRepository.findTopByFund_FundId(fundId).orElse(null);

        // ── 상품/문서 조회 (있으면 productView에 담아 둔 뒤 DTO 빌드에 포함)
        FundProductView productView = fundProductRepository
                .findTopByFund_FundIdOrderByProductIdDesc(fundId)
                .map(p -> {
                    List<FundProductDocDto> docs = new ArrayList<>();
                    addDoc(docs, p.getSummaryDocId(),    "SUMMARY");
                    addDoc(docs, p.getProspectusDocId(), "PROSPECTUS");
                    addDoc(docs, p.getTermsDocId(),      "TERMS");
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
                                : latestStatus.getNavTotal().intValue()   // Integer에 맞춤
                )
                .return1m(latestReturn == null ? null : latestReturn.getReturn1m())
                .return3m(latestReturn == null ? null : latestReturn.getReturn3m())
                .return6m(latestReturn == null ? null : latestReturn.getReturn6m())
                .return12m(latestReturn == null ? null : latestReturn.getReturn12m())
                .domesticStock(latestAsset == null ? null : latestAsset.getStockRatio())
                .domesticBond(latestAsset == null ? null : latestAsset.getBondRatio())
                .liquidity(latestAsset == null ? null : latestAsset.getCashRatio())
                .product(productView)
                .build();

        return ApiResponse.success(dto);
    }

    private void addDoc(List<FundProductDocDto> out, Long docId, String type) {
        if (docId == null) return;
        FundDocument d = fundDocumentRepository.findById(docId).orElse(null);

        String fileName = (d != null) ? d.getFileName()  : null;
        String path     = (d != null) ? d.getFilePath()  : null;
        out.add(new FundProductDocDto(docId, type, fileName, path));

        // 만약 엔티티가 docTitle/filePath 라면 위 두 줄을 getDocTitle/getFilePath 로 바꾸세요.
        out.add(new FundProductDocDto(docId, type, fileName, path));
    }
}