package com.example.batch_scraper.job.chunk;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

import org.springframework.batch.item.Chunk;
import org.springframework.batch.item.ItemWriter;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.dto.CompleteFundData;
import com.example.batch_scraper.dto.FundAssetSummaryDto;
import com.example.batch_scraper.dto.FundBondTypesDto;
import com.example.batch_scraper.dto.FundDto;
import com.example.batch_scraper.dto.FundFeeInfoDto;
import com.example.batch_scraper.dto.FundLiquidityAssetsDto;
import com.example.batch_scraper.dto.FundPriceDailyDto;
import com.example.batch_scraper.dto.FundReturnDto;
import com.example.batch_scraper.dto.FundStatusDailyDto;
import com.example.batch_scraper.dto.FundStockMarketDto;
import com.example.batch_scraper.entity.Fund;
import com.example.batch_scraper.entity.FundAssetSummary;
import com.example.batch_scraper.entity.FundBondTypes;
import com.example.batch_scraper.entity.FundFeeInfo;
import com.example.batch_scraper.entity.FundLiquidityAssets;
import com.example.batch_scraper.entity.FundPriceDaily;
import com.example.batch_scraper.entity.FundReturn;
import com.example.batch_scraper.entity.FundStatusDaily;
import com.example.batch_scraper.entity.FundStockMarket;
import com.example.batch_scraper.repository.FundAssetSummaryRepository;
import com.example.batch_scraper.repository.FundBondTypesRepository;
import com.example.batch_scraper.repository.FundFeeInfoRepository;
import com.example.batch_scraper.repository.FundLiquidityAssetsRepository;
import com.example.batch_scraper.repository.FundPriceDailyRepository;
import com.example.batch_scraper.repository.FundRepository;
import com.example.batch_scraper.repository.FundReturnRepository;
import com.example.batch_scraper.repository.FundStatusDailyRepository;
import com.example.batch_scraper.repository.FundStockMarketRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
@Transactional
public class FundDataWriter implements ItemWriter<CompleteFundData> {

	private final FundRepository fundRepo;
	private final FundStatusDailyRepository statusRepo;
	private final FundReturnRepository returnRepo;
	private final FundPriceDailyRepository priceDailyRepo; 
	private final FundFeeInfoRepository feeRepo;
	private final FundAssetSummaryRepository assetRepo;
	private final FundStockMarketRepository stockRepo;
	private final FundLiquidityAssetsRepository liquidRepo;
	private final FundBondTypesRepository bondRepo;
	
	
	@Override
	public void write(Chunk<? extends CompleteFundData> chunk) throws Exception {
		log.info("4단계 - FundDataWriter - 데이터 DB에 저장, 처리할 아이템 수: {}", chunk.size());
        
		for (CompleteFundData item : chunk) {
			try {
				String fundId = item.getFund().getFundId();
		        log.info("4단계 - 펀드 데이터 저장 시작: {}", fundId);

	            // 1. 펀드 기본 정보 저장 (부모 테이블 우선)
	            Fund savedFund = saveFundBasicInfo(item.getFund());

	            // 2. 수수료 정보 저장 (펀드 ID 참조)
	            if (item.getFeeInfo() != null) {
	                saveFundFeeInfo(savedFund, item.getFeeInfo());
	            }

	            // 3. 일자별 상태 정보 저장
	            if (item.getFundStatusDaily() != null) {
	                saveFundStatusDaily(savedFund, item.getFundStatusDaily());
	            }
	            
	            // 4. 수익률 정보 저장
	            if (item.getFundReturn() != null) {
	                saveFundReturn(savedFund, item.getFundReturn());
	            }
	            
	            // 5. 일자별 가격 정보 저장 (리스트)
	            if (item.getFundPriceDailyList() != null && !item.getFundPriceDailyList().isEmpty()) {
	                saveFundPriceDailyList(savedFund, item.getFundPriceDailyList());
	            }
	            
	            // 6. 자산 구성 요약 저장
	            if (item.getFundAssetSummary() != null) {
	                saveFundAssetSummary(savedFund, item.getFundAssetSummary());
	            }
	            
	            // 7. 채권 유형 구성 저장
	            if (item.getFundBondTypes() != null) {
	                saveFundBondTypes(savedFund, item.getFundBondTypes());
	            }
	            
	            // 8. 유동성 자산 저장
	            if (item.getFundLiquidityAssets() != null) {
	                saveFundLiquidityAssets(savedFund, item.getFundLiquidityAssets());
	            }
	            
	            // 9. 주식 시장 비중 저장
	            if (item.getFundStockMarket() != null) {
	                saveFundStockMarket(savedFund, item.getFundStockMarket());
	            }
	            
	            log.info("4단계 - 펀드 데이터 저장 완료: {}", fundId);
			} catch (Exception e) {
                log.error("4단계 - 펀드 데이터 저장 실패: {}, 오류: {}", item.getFund() != null ? item.getFund().getFundId() : "Unknown", e.getMessage(), e);
                throw e; // 전체 청크 롤백
            }
	    }
        
        log.info("4단계 - 청크 저장 완료: {} 건", chunk.size());
	}
	
	
	

    /**
     * 펀드 기본 정보 저장 (UPSERT)
     */
	private Fund saveFundBasicInfo(FundDto dto) {
        Fund entity = fundRepo.findById(dto.getFundId())
            .orElse(Fund.builder()
                .fundId(dto.getFundId())
                .build());
        
        // DTO → Entity 매핑
        entity.setFundName(dto.getFundName());
        entity.setFundType(dto.getFundType());
        entity.setFundDivision(dto.getFundDivision());
        entity.setInvestmentRegion(dto.getInvestmentRegion());
        entity.setSalesRegionType(dto.getSalesRegionType());
        entity.setGroupCode(dto.getGroupCode());
        entity.setShortCode(dto.getShortCode());
        entity.setIssueDate(dto.getIssueDate());
        entity.setInitialNavPrice(dto.getInitialNavPrice());
        entity.setTrustTerm(dto.getTrustTerm());
        entity.setAccountingPeriod(dto.getAccountingPeriod());
        entity.setFundClass(dto.getFundClass());
        entity.setPublicType(dto.getPublicType());
        entity.setAddUnitType(dto.getAddUnitType());
        entity.setFundStatus(dto.getFundStatus());
        entity.setRiskGrade(dto.getRiskGrade());
        entity.setPerformanceDisclosure(dto.getPerformanceDisclosure());
        entity.setManagementCompany(dto.getManagementCompany());
        entity.setMinSubscriptionAmount(dto.getMinSubscriptionAmount());
        
        return fundRepo.save(entity);
    }

	/**
     * 펀드 수수료 정보 저장
     */
    private void saveFundFeeInfo(Fund fund, FundFeeInfoDto dto) {
        // 기존 데이터 삭제 후 재생성 (수수료는 최신 정보로 대체)
        feeRepo.deleteByFund(fund);
        
        FundFeeInfo entity = FundFeeInfo.builder()
            .fund(fund)
            .managementFee(dto.getManagementFee())
            .salesFee(dto.getSalesFee())
            .adminFee(dto.getAdminFee())
            .trustFee(dto.getTrustFee())
            .totalFee(dto.getTotalFee())
            .ter(dto.getTer())
            .frontLoadFee(dto.getFrontLoadFee())
            .rearLoadFee(dto.getRearLoadFee())
            .build();
        
        feeRepo.save(entity);
    }

    /**
     * 펀드 일자별 상태 저장
     */
    private void saveFundStatusDaily(Fund fund, FundStatusDailyDto dto) {
        // 동일 펀드ID + 기준일자로 중복 체크
        if (statusRepo.existsByFundAndBaseDate(fund, dto.getBaseDate())) {
            log.debug("이미 존재하는 일자별 상태 데이터: fundId={}, baseDate={}", 
                fund.getFundId(), dto.getBaseDate());
            return;
        }
        
        FundStatusDaily entity = FundStatusDaily.builder()
            .fund(fund)
            .baseDate(dto.getBaseDate())
            .navPrice(dto.getNavPrice())
            .navTotal(dto.getNavTotal())
            .originalPrincipal(dto.getOriginalPrincipal())
            .navChange1d(dto.getNavChange1d())
            .navChangeRate1d(dto.getNavChangeRate1d())
            .navChange1w(dto.getNavChange1w())
            .navChangeRate1w(dto.getNavChangeRate1w())
            .build();
        
        statusRepo.save(entity);
    }
    
    /**
     * 펀드 수익률 저장
     */
    private void saveFundReturn(Fund fund, FundReturnDto dto) {
        // 동일 펀드ID + 기준일자로 중복 체크
        if (returnRepo.existsByFundAndBaseDate(fund, dto.getBaseDate())) {
            log.debug("이미 존재하는 수익률 데이터: fundId={}, baseDate={}", 
                fund.getFundId(), dto.getBaseDate());
            return;
        }
        
        FundReturn entity = FundReturn.builder()
            .fund(fund)
            .baseDate(dto.getBaseDate())
            .return1m(dto.getReturn1m())
            .return3m(dto.getReturn3m())
            .return6m(dto.getReturn6m())
            .return12m(dto.getReturn12m())
            .build();
        
        returnRepo.save(entity);
    }

    /**
     * 펀드 일자별 가격 정보 저장 (배치 처리)
     */
    private void saveFundPriceDailyList(Fund fund, List<FundPriceDailyDto> dtoList) {
        List<FundPriceDaily> entities = new ArrayList<>();
        
        for (FundPriceDailyDto dto : dtoList) {
            // 중복 체크
            if (priceDailyRepo.existsByFundAndBaseDate(fund, dto.getBaseDate())) {
                log.debug("이미 존재하는 일자별 가격 데이터: fundId={}, baseDate={}", 
                    fund.getFundId(), dto.getBaseDate());
                continue;
            }
            
            FundPriceDaily entity = FundPriceDaily.builder()
                .fund(fund)
                .baseDate(dto.getBaseDate())
                .navPrice(dto.getNavPrice())
                .navChange(dto.getNavChange())
                .taxPrice(dto.getTaxPrice())
                .originalPrincipal(dto.getOriginalPrincipal())
                .kospi(dto.getKospi())
                .kospi200(dto.getKospi200())
                .kosdaq(dto.getKosdaq())
                .treasury3y(dto.getTreasury3y())
                .corpBond3y(dto.getCorpBond3y())
                .build();
            
            entities.add(entity);
        }
        
        if (!entities.isEmpty()) {
            priceDailyRepo.saveAll(entities); // 배치 저장
            log.debug("일자별 가격 데이터 저장: fundId={}, 건수={}", fund.getFundId(), entities.size());
        }
    }

    /**
     * 펀드 자산 구성 요약 저장
     */
    private void saveFundAssetSummary(Fund fund, FundAssetSummaryDto dto) {
        // 기존 데이터 삭제 후 재생성 (최신 구성 비율로 대체)
        assetRepo.deleteByFund(fund);
        
        // DTO에 baseDate가 없으므로 현재 날짜 사용
        LocalDate baseDate = LocalDate.now();
        
        FundAssetSummary entity = FundAssetSummary.builder()
            .fund(fund)
            .baseDate(baseDate)
            .stockRatio(dto.getStockRatio())
            .bondRatio(dto.getBondRatio())
            .cashRatio(dto.getCashRatio())
            .etcRatio(dto.getEtcRatio())
            .build();
        
        assetRepo.save(entity);
    }
    /**
     * 펀드 채권 유형 구성 저장
     */
    private void saveFundBondTypes(Fund fund, FundBondTypesDto dto) {
        bondRepo.deleteByFund(fund);
        
        LocalDate baseDate = LocalDate.now();
        
        FundBondTypes entity = FundBondTypes.builder()
            .fund(fund)
            .baseDate(baseDate)
            .govBondRatio(dto.getGovBondRatio())
            .moaBondRatio(dto.getMoaBondRatio())
            .finBondRatio(dto.getFinBondRatio())
            .corpBondRatio(dto.getCorpBondRatio())
            .otherRatio(dto.getOtherRatio())
            .build();
        
        bondRepo.save(entity);
    }	
    /**
     * 펀드 유동성 자산 저장
     */
    private void saveFundLiquidityAssets(Fund fund, FundLiquidityAssetsDto dto) {
        liquidRepo.deleteByFund(fund);
        
        LocalDate baseDate = LocalDate.now();
        
        FundLiquidityAssets entity = FundLiquidityAssets.builder()
            .fund(fund)
            .baseDate(baseDate)
            .cdRatio(dto.getCdRatio())
            .cpRatio(dto.getCpRatio())
            .callLoanRatio(dto.getCallLoanRatio())
            .depositRatio(dto.getDepositRatio())
            .otherRatio(dto.getOtherRatio())
            .build();
        
        liquidRepo.save(entity);
    }
    /**
     * 펀드 주식 시장 비중 저장
     */
    private void saveFundStockMarket(Fund fund, FundStockMarketDto dto) {
        stockRepo.deleteByFund(fund);
        
        LocalDate baseDate = LocalDate.now();
        
        FundStockMarket entity = FundStockMarket.builder()
            .fund(fund)
            .baseDate(baseDate)
            .kseRatio(dto.getKseRatio())
            .kosdaqRatio(dto.getKosdaqRatio())
            .otherRatio(dto.getOtherRatio())
            .build();
        
        stockRepo.save(entity);
    }


}