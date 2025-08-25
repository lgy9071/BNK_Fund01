package com.example.fund.account.service;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.example.fund.account.dto.DocumentInfoDto;
import com.example.fund.fund.entity_fund.FundDocument;
import com.example.fund.fund.entity_fund.FundProduct;
import com.example.fund.fund.repository_fund.FundDocumentRepository;
import com.example.fund.fund.repository_fund.FundProductRepository;
import com.example.fund.fund.repository_fund.FundRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundInfoService {
	
	private final FundRepository fundRepo;
	private final FundProductRepository fundProductRepository;
	private final FundDocumentRepository fundDocumentRepository;
	
	public BigDecimal checkFundNavPrice(String fundId) {
		
		return fundRepo.findMinSubscriptionAmountByFundId(fundId).get();

	}
	
	public List<DocumentInfoDto> getRequiredDocs(String fundId) {
        FundProduct p = fundProductRepository.findByFund_FundId(fundId);

        List<DocumentInfoDto> out = new ArrayList<>();

        // 간이투자설명서
        if (p.getSummaryDocId() != null) {
            FundDocument d = fundDocumentRepository.findById(p.getSummaryDocId())
                    .orElseThrow(() -> new IllegalStateException("summary document not found"));
            out.add(toDto(d, "[필수] 간이투자설명서 동의"));
        }

        // 투자설명서
        if (p.getProspectusDocId() != null) {
            FundDocument d = fundDocumentRepository.findById(p.getProspectusDocId())
                    .orElseThrow(() -> new IllegalStateException("prospectus document not found"));
            out.add(toDto(d, "[필수] 투자설명서 동의"));
        }

        // 이용약관
        if (p.getTermsDocId() != null) {
            FundDocument d = fundDocumentRepository.findById(p.getTermsDocId())
                    .orElseThrow(() -> new IllegalStateException("terms document not found"));
            out.add(toDto(d, "[필수] 상품약관 동의"));
        }

        return out;
    }

    private DocumentInfoDto toDto(FundDocument d, String title) {
        // 정적 리소스 경로: src/main/resources/static/fund_document/{fileName}
        // 배포 시 접근 경로: /fund_document/{fileName}
        String url = "/fund_document/" + d.getFileName();
        String typeKo = switch (d.getDocType()) {
            case "간이투자설명서" -> "간이투자설명서";
            case "투자설명서" -> "투자설명서";
            case "이용약관"   -> "이용약관";
            default -> d.getDocType();
        };
        return DocumentInfoDto.builder()
                .type(typeKo)
                .title(title)
                .url(url)
                .build();
    }
	
	
	
//	public BigDecimal checkFundNavPrice(String fundId) {
//	    BigDecimal navPrice = fundStatusDailyRepo
//	            .findNavPriceByFundIdAndBaseDate(fundId, LocalDate.now())
//	            .orElseThrow(() -> new IllegalStateException("NAV not found for fundId=" + fundId));
//
//	    if (navPrice.signum() <= 0) {
//	        throw new IllegalStateException("Invalid NAV price: " + navPrice);
//	    }
//
//	    // ✅ NAV 가격을 1000원 단위에서 무조건 올림 (정수만 반환)
//	    BigDecimal unit = BigDecimal.valueOf(1000);
//	    return navPrice
//	            .divide(unit, 0, RoundingMode.CEILING) // 천원 단위로 나눈 뒤 무조건 올림
//	            .multiply(unit);                        // 다시 천원 단위 곱하기
//	}

}
