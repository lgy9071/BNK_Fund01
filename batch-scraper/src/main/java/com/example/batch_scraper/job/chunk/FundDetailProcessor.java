package com.example.batch_scraper.job.chunk;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.dto.CompleteFundData;
import com.example.batch_scraper.dto.FundAssetSummaryDto;
import com.example.batch_scraper.dto.FundBondTypesDto;
import com.example.batch_scraper.dto.FundDto;
import com.example.batch_scraper.dto.FundFeeInfoDto;
import com.example.batch_scraper.dto.FundLiquidityAssetsDto;
import com.example.batch_scraper.dto.FundPriceDailyDto;
import com.example.batch_scraper.dto.FundReturnDto;
import com.example.batch_scraper.dto.FundRowData;
import com.example.batch_scraper.dto.FundStatusDailyDto;
import com.example.batch_scraper.dto.FundStockMarketDto;
import com.example.batch_scraper.selenium.SeleniumDriverManager;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Component
@RequiredArgsConstructor
@Slf4j
public class FundDetailProcessor implements ItemProcessor<FundRowData, CompleteFundData> {

	private final SeleniumDriverManager webDriverManager;
	private final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("yyyy/MM/dd");
	private final int AFTER_SCROLL_WAIT_MS = 1000;
	private final int AFTER_NEW_TAB_WAIT_MS = 1000;
	private final int AFTER_TAB_CLICK_WAIT_MS = 1000;
	private final int UNTIL_NUMBER_WAIT_MS = 5000;
	

	@Override
	public CompleteFundData process(FundRowData fundRowData) throws Exception {

		try {
			log.info("4단계 - FundDetailProcessor - 상세 데이터 추출");

			if (fundRowData == null) {
				log.info("4단계 - 유효하지 않은 데이터");
				return null;
			}

			String fundId = fundRowData.getStandardCode();
			String fundName = fundRowData.getFundName();
			String riskGrade = fundRowData.getRiskRate();
			BigDecimal return1M = new BigDecimal(fundRowData.getRet1M());
			BigDecimal return3M = new BigDecimal(fundRowData.getRet3M());
			BigDecimal return6M = new BigDecimal(fundRowData.getRet6M());
			BigDecimal return12M = new BigDecimal(fundRowData.getRet12M());

			WebDriver driver = webDriverManager.getDriver();
			WebDriverWait wait = webDriverManager.getWait();
			String originalWindow = driver.getWindowHandle();

			CompleteFundData result = new CompleteFundData();

			// 상세 페이지 URL 생성 ================
			// https://dis.kofia.or.kr/websquare/popup.html?w2xPath=/wq/com/popup/DISComFundSmryInfo.xml&standardCd=KR5207504634
			String detailUrl = "https://dis.kofia.or.kr/websquare/popup.html?w2xPath=/wq/com/popup/DISComFundSmryInfo.xml&standardCd=" + fundId;
			log.info("4단계 - 상세 페이지 url 생성");

			try {
				// 새 탭 열기 =====================
				log.info("4단계 - 새 탭 열기");
				JavascriptExecutor js = (JavascriptExecutor) driver;
				js.executeScript("window.open(arguments[0], '_blank');", detailUrl);
				Thread.sleep(AFTER_NEW_TAB_WAIT_MS); // 불안정해서 고정값을 통한 대기

				// 새 탭으로 전환 ==================
				log.info("4단계 - 새 탭으로 전환");
				Set<String> windowHandles = driver.getWindowHandles();
				String newWindow = null;
				for (String handle : windowHandles) {
					if (!handle.equals(originalWindow)) {
						newWindow = handle;
						break;
					}
				}
				driver.switchTo().window(newWindow);

				// 페이지 로딩 대기 ====================================================
				log.info("4단계 - 페이지 로딩 대기");
				waitLoading(wait);
				Thread.sleep(AFTER_TAB_CLICK_WAIT_MS);	// 불안정해서 고정값을 통한 대기

				// 상세 데이터 추출 ====================================================
				log.info("4단계 - 상세 데이터 추출 시작");
				// 상단 기본 데이터 추출
				// 날짜
				String baseDataStr = getElementText(wait, "standardDt03");
				LocalDate baseDate = LocalDate.parse(getDateText(baseDataStr), DATE_FMT);

				// 기준가
				BigDecimal navPrice = new BigDecimal(getOnlyText(getElementText(wait, "StandardCot")));
				// 전일 대비 -14.1949, -0.39%) <== 예시 데이터
				String oneDay = getElementText(wait, "lstDayValue");
				String[] oneDayParts = oneDay.replaceAll("[()%]", "").trim().split(",");
				BigDecimal navChange1d = new BigDecimal(getOnlyText(oneDayParts[0]));
				BigDecimal navChangeRate1d = new BigDecimal(getOnlyText(oneDayParts[1]));

				// 전주 대비 112.2812, 3.18%) <== 예시 데이터
				String oneWeek = getElementText(wait, "lstWeekValue");
				String[] oneWeekParts = oneWeek.replaceAll("[()%]", "").trim().split(",");
				BigDecimal navChange1w = new BigDecimal(getOnlyText(oneWeekParts[0]));
				BigDecimal navChangeRate1w = new BigDecimal(getOnlyText(oneWeekParts[1]));

				// 설정 원본 12,894
				BigDecimal originalPrincipal = new BigDecimal(getOnlyText(getElementText(wait, "tOriginalAmt")));  
				// 순자산 총액 12,894
				BigDecimal navTotal = new BigDecimal(getOnlyText(getElementText(wait, "tNetAsstotAmt")));  
				// 운용상태 운용중
				String fundStatus = getOnlyText(getElementText(wait, "tVal4"));

				// 펀드 기본 정보 탭 영역 ====================================================
				String fundType = getOnlyText(getElementText(wait, "FundGbNm"));
				String fundDivision = getOnlyText(getElementText(wait, "FundTypNm"));
				String investmentRegion = getOnlyText(getElementText(wait, "InvestRgnGbNm"));
				String salesRegionType = getOnlyText(getElementText(wait, "SaleRgnGbNm"));
				String groupCode = getOnlyText(getElementText(wait, "ClassCd"));
				String shortCode = getOnlyText(getElementText(wait, "ShortCd"));
				LocalDate issueDate = LocalDate.parse(getOnlyText(getElementText(wait, "EstablishmentDt")), DATE_FMT);  
				BigDecimal initialNavPrice = new BigDecimal(getOnlyText(getElementText(wait, "EstablishmentCot")));
				Integer trustTerm = Integer.valueOf(getOnlyText(getElementText(wait, "TrustTrm")));
				Integer accountingPeriod = Integer.valueOf(getOnlyText(getElementText(wait, "TrustAccTrm")));
				String fundClass = getOnlyText(getElementText(wait, "TraitDivNm"));
				String publicType = getOnlyText(getElementText(wait, "PriPubGBNm"));
				String addUnitType = getOnlyText(getElementText(wait, "AdditionalEstMtdNm"));
				String performanceDisclosure = getOnlyText(getElementText(wait, "ProfitTypeCdNm"));
				String managementCompany = getOnlyText(getElementText(wait, "ManageCompNm"));
				BigDecimal minSubscriptionAmount = ceilToThousand(navPrice);
				
				BigDecimal managementFee = new BigDecimal(removeParentheses(getOnlyText(getElementText(wait, "ManageRewRate"))));
				BigDecimal salesFee = new BigDecimal(removeParentheses(getOnlyText(getElementText(wait, "SaleRewRate"))));
				BigDecimal trustFee = new BigDecimal(removeParentheses(getOnlyText(getElementText(wait, "TrustRewRate"))));
				BigDecimal adminFee = new BigDecimal(removeParentheses(getOnlyText(getElementText(wait, "GeneralOfctrtrewRate"))));
				BigDecimal totalFee = new BigDecimal(removeParentheses(getOnlyText(getElementText(wait, "RewSum"))));
				BigDecimal ter = new BigDecimal(removeParentheses(getOnlyText(getElementText(wait, "Ter"))));
				BigDecimal frontLoadFee = new BigDecimal(getOnlyText(getElementText(wait, "FrontendCmsRate")));
				BigDecimal rearLoadFee = new BigDecimal(getOnlyText(getElementText(wait, "BackendCmsRate")));

				// 자산 구성 내역 탭 영역 ====================================================
				// 탭 이동
				moveToTab(wait, "tabControl2_tab_detTab4");
				Thread.sleep(AFTER_TAB_CLICK_WAIT_MS);
				WebDriverWait untilWait = new WebDriverWait(driver, Duration.ofSeconds(30000));
				untilWait.until(d -> {
				    try {
				        String stockText = getElementText(wait, "vAssetsCmpsStockRtLbl");
				        String bondText = getElementText(wait, "vAssetsCmpsBondRtLbl");
				        String cashText = getElementText(wait, "vAssetsCmpsLiquidRtLbl");
				        String etcText = getElementText(wait, "vAssetsCmpsEtcRtLbl");
				        
				        return isValidBigDecimal(stockText) && isValidBigDecimal(bondText) && isValidBigDecimal(cashText) && isValidBigDecimal(etcText);
				    } catch (Exception e) {
				        return false;
				    }
				});
				BigDecimal stockRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsStockRtLbl")));
				BigDecimal bondRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsBondRtLbl")));
				BigDecimal cashRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsLiquidRtLbl")));
				BigDecimal etcRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsEtcRtLbl")));

				BigDecimal kseRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsStockKseRtLbl")));
				BigDecimal kosdaqRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsStockKosdaqRtLbl")));
				BigDecimal stockMarket_otherRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsStockEtcRtLbl")));

				BigDecimal cdRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsLiquidCdRtLbl")));
				BigDecimal cpRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsLiquidCpRtLbl")));
				BigDecimal callLoanRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsLiquidCallRtLbl")));
				BigDecimal depositRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsLiquidDpsRtLbl")));
				BigDecimal liquidity_otherRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsLiquidEtcRtLbl")));

				BigDecimal govBondRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsBondNatRtLbl")));
				BigDecimal moaBondRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsBondCurrRtLbl")));
				BigDecimal finBondRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsBondFinRtLbl")));
				BigDecimal corpBondRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsBondCompRtLbl")));
				BigDecimal bondTypes_otherRatio = new BigDecimal(getOnlyText(getElementText(wait, "vAssetsCmpsBondEtcRtLbl")));

				// 가격 변동 추이 탭 영역
				// 탭 이동
				moveToTab(wait, "tabControl2_tab_detTab3");
				Thread.sleep(AFTER_TAB_CLICK_WAIT_MS);
				List<FundPriceDailyDto> priceDailyList = getDailyPriceList(driver, wait, fundId);

				// 전체 데이터 DTO로 변형
				FundDto fundDto = FundDto.builder()
						.fundId(fundId)
						.fundName(fundName)
						.fundType(fundType)
						.fundDivision(fundDivision)
						.investmentRegion(investmentRegion)
						.salesRegionType(salesRegionType)
						.groupCode(groupCode)
						.shortCode(shortCode)
						.issueDate(issueDate)
						.initialNavPrice(initialNavPrice)
						.trustTerm(trustTerm)
						.accountingPeriod(accountingPeriod)
						.fundClass(fundClass)
						.publicType(publicType)
						.addUnitType(addUnitType)
						.fundStatus(fundStatus)
						.riskGrade(riskGrade)
						.performanceDisclosure(performanceDisclosure)
						.managementCompany(managementCompany)
						.minSubscriptionAmount(minSubscriptionAmount)
						.build();

				FundFeeInfoDto feeDto = FundFeeInfoDto.builder()
						.fundId(fundId)
						.managementFee(managementFee)
						.salesFee(salesFee)
						.adminFee(adminFee)
						.trustFee(trustFee)
						.totalFee(totalFee)
						.ter(ter)
						.frontLoadFee(frontLoadFee)
						.rearLoadFee(rearLoadFee)
						.build();

				FundStatusDailyDto statusDailyDto = FundStatusDailyDto.builder()
						.fundId(fundId)
						.baseDate(baseDate)
						.navPrice(navPrice)
						.navTotal(navTotal)
						.originalPrincipal(originalPrincipal)
						.navChange1d(navChange1d)
						.navChangeRate1d(navChangeRate1d)
						.navChange1w(navChange1w)
						.navChangeRate1w(navChangeRate1w)
						.build();

				FundReturnDto returnDto = FundReturnDto.builder()
						.fundId(fundId)
						.baseDate(baseDate)
						.return1m(return1M)
						.return3m(return3M)
						.return6m(return6M)
						.return12m(return12M)
						.build();

				FundAssetSummaryDto assetSummaryDto = FundAssetSummaryDto.builder()
						.fundId(fundId)
						.stockRatio(stockRatio)
						.bondRatio(bondRatio)
						.cashRatio(cashRatio)
						.etcRatio(etcRatio)
						.build();

				FundStockMarketDto stockMarketDto = FundStockMarketDto.builder()
						.fundId(fundId)
						.kseRatio(kseRatio)
						.kosdaqRatio(kosdaqRatio)
						.otherRatio(stockMarket_otherRatio)
						.build();

				FundLiquidityAssetsDto liquidityAssetsDto = FundLiquidityAssetsDto.builder()
						.fundId(fundId)
						.cdRatio(cdRatio)
						.cpRatio(cpRatio)
						.callLoanRatio(callLoanRatio)
						.depositRatio(depositRatio)
						.otherRatio(liquidity_otherRatio)
						.build();

				FundBondTypesDto bondTypesDto = FundBondTypesDto.builder()
						.fundId(fundId)
						.govBondRatio(govBondRatio)
						.moaBondRatio(moaBondRatio)
						.finBondRatio(finBondRatio)
						.corpBondRatio(corpBondRatio)
						.otherRatio(bondTypes_otherRatio)
						.build();

				result.setFund(fundDto);
				result.setFeeInfo(feeDto);
				result.setFundStatusDaily(statusDailyDto);
				result.setFundReturn(returnDto);
				result.setFundAssetSummary(assetSummaryDto);
				result.setFundStockMarket(stockMarketDto);
				result.setFundLiquidityAssets(liquidityAssetsDto);
				result.setFundBondTypes(bondTypesDto);
				result.setFundPriceDailyList(priceDailyList);

				log.info("4단계 - 상세 데이터 추출 완료");
			} finally {
				log.info("4단계 - 탭 정리 및 원래 창 복귀 중...");

				driver.close();
				driver.switchTo().window(originalWindow);

			}

			log.info("4단계 - processing 완료");
			return result;
		} catch (Exception e) {
			log.error("4단계 - processing 실패: {}", e);
			throw e;
		}
	}

	// 요소 텍스트 추출
	private String getElementText(WebDriverWait wait, String elementId) {
		WebElement element = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id(elementId)));
		return element.getText().trim();
	}
	/* 
	legacy code
	private String getElementText(WebDriver driver, String elementId) {
		// WebElement element = driver.findElement(By.id(elementId));
		return element.getText().trim();
	}
	*/

	// 셀 기반 텍스트 추출
	private String getCellText(WebElement row, String colId) {
		WebElement item = row.findElement(By.cssSelector("td[col_id='" + colId + "'] nobr"));
		return item.getText().trim();
	}

	// - 또는 , 문자 제거
	private String getOnlyText(String s) {
		s = s.trim();
		if (s.isEmpty() || "-".equals(s))
			return null;
		if (s.contains(","))
			s = s.replace(",", "");
		return s;
	}

	// 날짜 형식 텍스트만 추출
	private String getDateText(String text) {
		// 정규식으로 날짜 패턴 추출
		Pattern pattern = Pattern.compile("(\\d{4}/\\d{2}/\\d{2})");
		Matcher matcher = pattern.matcher(text);

		if (matcher.find()) {
			String dateStr = matcher.group(1);
			return dateStr;
		}

		return text; // 실패 시 원본 반환
	}

	// 1000단위로 올림
	public static BigDecimal ceilToThousand(BigDecimal value) {
		if (value == null) return BigDecimal.ZERO; // 필요시 BigDecimal.ZERO로 바꿔도 됨
		BigDecimal thousand = BigDecimal.valueOf(1000);
		return value.divide(thousand, 0, RoundingMode.CEILING) // 천 단위로 나눈 값을 올림
				.multiply(thousand); // 다시 천을 곱해 원 단위로 복원
	}

	// 괄호와 괄호 안의 내용을 제거하는 헬퍼 메서드 예: "0.25 (0.312)" → "0.25"
	private String removeParentheses(String text) {
		return text.replaceAll("\\s*\\([^)]*\\)", "").trim();
	}
	
	/** 숫자 형태인지 검증 */
	private boolean isValidBigDecimal(String text) {
	    try {
	        String cleanText = getOnlyText(text);
	        if (cleanText.isEmpty()) return false;
	        new BigDecimal(cleanText);
	        return true;
	    } catch (NumberFormatException e) {
	        return false;
	    }
	}

	// 탭 이동
	private void moveToTab(WebDriverWait wait, String tabId) {
		// WebElement tab = driver.findElement(By.id(tabId));
		WebElement tab = wait.until(ExpectedConditions.elementToBeClickable(By.id(tabId)));
		tab.click();
		waitLoading(wait);
	}

	// 로딩창 대기
	private void waitLoading(WebDriverWait wait) {
		wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("loadingBox")));
		
		/*
		wait.until(ExpectedConditions.or(
			ExpectedConditions.invisibilityOfElementLocated(By.id("disLoadingPop")),
			ExpectedConditions.invisibilityOfElementLocated(By.id("loadingBox")))
		);
		*/
	}

	// 스크롤
	private void scrollDown(WebDriver driver) {
		WebElement scroller = driver.findElement(By.id("priceModGrid_scrollY_div"));
		JavascriptExecutor js = (JavascriptExecutor) driver;

		// 현재 스크롤 위치 확인
		Long currentScrollTop = (Long) js.executeScript("return arguments[0].scrollTop;", scroller);

		// 스크롤 제어
		int scroll = 100; // 75:4, 100:5, (115,111):6, 160:8, 175:9
		long newScrollTop = currentScrollTop + scroll;
		js.executeScript("arguments[0].scrollTop = arguments[1];", scroller, newScrollTop);
	}

	private List<FundPriceDailyDto> getDailyPriceList(WebDriver driver, WebDriverWait wait, String fundId) {
		// 전체 일일 데이터 갯수
		String allCountStr = getElementText(wait, "priceModCount");
		if (allCountStr.contains(","))
			allCountStr = allCountStr.replace(",", "").trim();
		final int allCount = Integer.parseInt(allCountStr);

		// List<FundPriceDailyDto> out = new ArrayList<>(Math.min(allCount, 5000));
		// Set<String> seenBaseDates = new HashSet<>((int)(allCount * 1.3));
		List<FundPriceDailyDto> result = new ArrayList<>();
		Set<String> seenBaseDates = new HashSet<>();

		boolean limitReached = false;
		Integer fetched = 0;

		try {
			while (seenBaseDates.size() < allCount) {
				List<WebElement> rows = driver.findElements(By.cssSelector("tr.grid_body_row"));
				if (rows.isEmpty()) {
					log.warn("4단계 - 일일 기준가 테이블에 데이터가 존재하지 않습니다");
					break;
				}

				for (WebElement row : rows) {
					// List<WebElement> cells = row.findElements(By.tagName("td"));
					String baseDateStr = getCellText(row, "standardDt");
					if (baseDateStr == null || baseDateStr.isBlank() || "-".equals(baseDateStr))
						continue;
					if (!seenBaseDates.add(baseDateStr))
						continue; // 이미 처리한 날짜면 skip

					LocalDate baseDate = LocalDate.parse(baseDateStr, DATE_FMT);
					BigDecimal navPrice = new BigDecimal(getOnlyText(getCellText(row, "standardCot")));
					BigDecimal navChange = new BigDecimal(getOnlyText(getCellText(row, "vBefDayFltstdcot")));
					BigDecimal taxPrice = new BigDecimal(getOnlyText(getCellText(row, "standardassStdCot")));
					BigDecimal originalPrincipal = new BigDecimal(getOnlyText(getCellText(row, "uOriginalAmt")));
					BigDecimal kospi = new BigDecimal(getOnlyText(getCellText(row, "kospiEpn")));
					BigDecimal kospi200 = new BigDecimal(getOnlyText(getCellText(row, "kospi200Epn")));
					BigDecimal kosdaq = new BigDecimal(getOnlyText(getCellText(row, "kosdaqEpn")));
					BigDecimal treasury3y = new BigDecimal(getOnlyText(getCellText(row, "tbondBnd3y")));
					BigDecimal corpBond3y = new BigDecimal(getOnlyText(getCellText(row, "companyBnd3y")));

					FundPriceDailyDto dto = FundPriceDailyDto.builder().fundId(fundId)
							.baseDate(baseDate)
							.navPrice(navPrice)
							.navChange(navChange)
							.taxPrice(taxPrice)
							.originalPrincipal(originalPrincipal)
							.kospi(kospi)
							.kospi200(kospi200)
							.kosdaq(kosdaq)
							.treasury3y(treasury3y)
							.corpBond3y(corpBond3y)
							.build();

					result.add(dto);
					fetched++;

					// 다 채웠다면 종료
					if (seenBaseDates.size() >= allCount) {
						limitReached = true;
						break;
					}
				}
				if (limitReached)
					break;

				scrollDown(driver);
				Thread.sleep(AFTER_SCROLL_WAIT_MS);
			}
		} catch (InterruptedException e) {
			log.error("4단계 - 펀드 목록 수집 실패", e);
		}

		return result;
	}
}

/*
 * 
 * dailyData.put("navPrice", cells.get(1).getText().trim());
 * dailyData.put("navChange", cells.get(2).getText().trim());
 * dailyData.put("taxPrice", cells.get(3).getText().trim());
 * dailyData.put("originalPrincipal", cells.get(4).getText().trim());
 * dailyData.put("kospi", cells.get(5).getText().trim());
 * dailyData.put("kospi200", cells.get(6).getText().trim());
 * dailyData.put("kosdaq", cells.get(7).getText().trim());
 * dailyData.put("treasury3y", cells.get(8).getText().trim());
 * dailyData.put("corpBond3y", cells.get(9).getText().trim());
 * 
 * 
 * 
 * // 새 탭 열기 ===================== log.info("4단계 - 새 탭 열기"); // String
 * parentHandle = driver.getWindowHandle(); // 현재 탭(부모) 핸들 저장 // Set<String>
 * handlesBefore = driver.getWindowHandles(); // 열기 전 핸들 스냅샷 JavascriptExecutor
 * js = (JavascriptExecutor) driver;
 * js.executeScript("window.open(arguments[0], '_blank');", detailUrl);
 * Thread.sleep(AFTER_NEW_TAB_WAIT_MS); // 불안정해서 고정값을 통한 대기
 * 
 * // 새 탭으로 전환 ================== log.info("4단계 - 새 탭으로 전환"); // wait.until(d ->
 * driver.getWindowHandles().size() > handlesBefore.size()); // 새 탭이 추가될 때까지 대기
 * // Set<String> handlesAfter = new HashSet<>(driver.getWindowHandles()); //
 * 증가한 핸들만 추출 -> 그게 새 탭 // handlesAfter.removeAll(handlesBefore); // String
 * newTabHandle = handlesAfter.iterator().next();
 * driver.switchTo().window(newTabHandle); // 새 탭으로 전환
 * 
 * 
 * 
 * 
 * 
 */
