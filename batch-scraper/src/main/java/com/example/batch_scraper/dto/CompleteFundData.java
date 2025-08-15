package com.example.batch_scraper.dto;

import java.util.List;

import lombok.Data;
import lombok.extern.slf4j.Slf4j;

/**
 * 펀드 전체 데이터를 담는 통합 모델
 * Chunk Processor에서 Reader → Writer로 전달되는 데이터
 */
@Data
@Slf4j
public class CompleteFundData {

    /** 펀드 기본 정보 (단건) */
    private FundDto fund;

    /** 수수료/보수 정보 (단건) */
    private FundFeeInfoDto feeInfo;

    /** 일자별 운용 상태 (예: 기준가/순자산/설정원본/변동 등) */
    private FundStatusDailyDto fundStatusDaily;

    /** 일자별 수익률 (1M/3M/6M/12M 등 요약값이 날짜별로 제공되는 경우) */
    private FundReturnDto fundReturn;

    /** 일자별 가격·지표(요청: List) */
    private List<FundPriceDailyDto> fundPriceDailyList;

    /** 자산 구성 요약 */
    private FundAssetSummaryDto fundAssetSummary;

    /** 채권 유형 구성 비중 */
    private FundBondTypesDto fundBondTypes;

    /** 유동성 자산 비중 */
    private FundLiquidityAssetsDto fundLiquidityAssets;

    /** 주식시장 비중 */
    private FundStockMarketDto fundStockMarket;
}
