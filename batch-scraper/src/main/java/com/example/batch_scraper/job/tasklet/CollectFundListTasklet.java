package com.example.batch_scraper.job.tasklet;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.SearchContext;
import org.openqa.selenium.StaleElementReferenceException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.batch.core.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.item.ExecutionContext;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.dto.FundRowData;
import com.example.batch_scraper.selenium.SeleniumDriverManager;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 3단계: 펀드 목록 수집
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CollectFundListTasklet implements Tasklet {

	private final SeleniumDriverManager webDriverManager;

	private final boolean ALL_SEARCH_ROW = false;
	private final int MAX_SEARCH_ROW = 50;	//
	private final int AFTER_SCROLL_WAIT_MS = 500;

	// ====== 내부 상수/로케이터 ======
	private static final By LOADING_POPUP = By.id("disLoadingPop");
	private static final By LOADING_BOX = By.id("loadingBox");
	private static final By TBODY = By.id("grdMain_body_tbody");
	private static final By VISIBLE_ROWS = By.cssSelector("tr.grid_body_row:not(.w2grid_hidedRow):not([style*='display: none'])");

	private static final By SCROLL_Y = By.id("grdMain_scrollY_div");
	private static final By TOTAL_CNT = By.id("txtGridCnt");
	private static final By IFRAME_BODY = By.id("multi_popup_contents_FundMngEptMgrStut_body");
	private static final By MODAL_CLOSE_BTN = By.className("btn_tab_pop_all_close");
	
	private static final By COL_FUND_NAME = By.cssSelector("td[col_id='fundNm']");
	private static final By COL_RISK = By.cssSelector("td[col_id='riskRate']");
	private static final By COL_RET_1M = By.cssSelector("td[col_id='ropGb1']");
	private static final By COL_RET_3M = By.cssSelector("td[col_id='ropGb2']");
	private static final By COL_RET_6M = By.cssSelector("td[col_id='ropGb3']");
	private static final By COL_RET_12M = By.cssSelector("td[col_id='ropGb5']");
	private static final By FUND_CODE = By.id("fundCode");
	private static final By COL_DETAIL_IMG = By.cssSelector("td[col_id='vGridChgImg1'] img");

	@Override
	public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
		log.info("3단계 - CollectFundListTasklet - 테이블 데이터 조회");

		try {
			WebDriver driver = webDriverManager.getDriver();
			WebDriverWait wait = webDriverManager.getWait();

			// 로딩 대기
			wait.until(ExpectedConditions.or(
			        ExpectedConditions.invisibilityOfElementLocated(LOADING_POPUP),
			        ExpectedConditions.invisibilityOfElementLocated(LOADING_BOX)
			));
			// 테이블 데이터 업로드 대기
			wait.until(ExpectedConditions.presenceOfElementLocated(TBODY));
			wait.until(ExpectedConditions.numberOfElementsToBeMoreThan(By.cssSelector("#grdMain_body_tbody > tr.grid_body_row:not(.w2grid_hidedRow):not([style*='display: none'])"), 0));
			
			List<FundRowData> out = new ArrayList<>();
	        Set<String> seen = new LinkedHashSet<>();

	        boolean limitReached = false;
	        Integer fetched = 0;
	        
	        // totalCnt를 정수로 변형	// String 3,315 -> Int or Integer 3315
            String totalCntStr = getInnerText(driver, findQuiet(driver, TOTAL_CNT));
            if(totalCntStr.contains(",")) {
            	totalCntStr = totalCntStr.replace(",", "").trim();
            }
            Integer totalCnt = Integer.parseInt(totalCntStr);
            
	        // 메인 루프: 보이는 행 → 수집 → 한 칸 스크롤 → 진전 여부 확인
	        while (true) {
	        	List<WebElement> rows = driver.findElements(VISIBLE_ROWS);
	        	
	        	if (rows.isEmpty()) {
					log.warn("3단계 - 테이블에 데이터가 존재하지 않습니다");
					break;
				}

	        	// 현재 테이블의 보이는 행 데이터 추출
	            for (WebElement row : rows) {
	                // 핵심 컬럼 읽기
	                String fundName = getInnerText(driver, findQuiet(row, COL_FUND_NAME));

	                if (fundName == null || fundName.isEmpty()) continue;
	                if (!seen.add(fundName)) continue;
	                
	                // 정보 추출
	                String risk     = getInnerText(driver, findQuiet(row, COL_RISK));
	                String ret1M    = getInnerText(driver, findQuiet(row, COL_RET_1M));
	                String ret3M    = getInnerText(driver, findQuiet(row, COL_RET_3M));
	                String ret6M    = getInnerText(driver, findQuiet(row, COL_RET_6M));
	                String ret12M   = getInnerText(driver, findQuiet(row, COL_RET_12M));
	                String standardCode = extractStandardCode(driver, wait, row);

	                FundRowData data = FundRowData.builder()
	                        .standardCode(standardCode)
	                        .fundName(fundName)
	                        .riskRate(risk)
	                        .ret1M(ret1M)
	                        .ret3M(ret3M)
	                        .ret6M(ret6M)
	                        .ret12M(ret12M)
	                        .build();
	                out.add(data);
	                fetched++;

	    	        log.info("3단계 - 현재 데이터 추출: {}건", fetched);
	                
	                // 상한 도달 시 끊기
	                int effectiveLimit = ALL_SEARCH_ROW ? totalCnt : Math.min(MAX_SEARCH_ROW, totalCnt);
	                if (out.size() >= effectiveLimit) {
	                    limitReached = true;
	                    break; 
	                }
	            }
	            if (limitReached) break;
	            
	            scrollDown(driver);					// 스크롤 수행 (1~9까지만 스크롤 제어)
	            Thread.sleep(AFTER_SCROLL_WAIT_MS);	// 불안정해서 고정값 만큼 대기
	        }
	        
	        log.info("3단계 - 수집 완료: {}건", out.size());

            // 전체 데이터 저장
	        ExecutionContext jobCtx = chunkContext
	                .getStepContext()
	                .getStepExecution()
	                .getJobExecution()
	                .getExecutionContext();
	        jobCtx.put("fundRowDataList", out);
		     
	        return RepeatStatus.FINISHED;
		} catch (Exception e) {
			log.error("3단계 - 펀드 목록 수집 실패", e);
			throw e;
		}
	}

	/** 요소 추출 */
	private WebElement findQuiet(SearchContext ctx, By by) {
		try {
			return ctx.findElement(by);
		} catch (Exception e) {
			return null;
		}
	}
	
	/** js를 통해 텍스트 추출 */
	private String getInnerText(WebDriver driver, WebElement el) {
	    if (el == null) return null;
	    try {
	        JavascriptExecutor js = (JavascriptExecutor) driver;

	        Object v = js.executeScript("return arguments[0].innerText;", el);
	        String s = v == null ? "" : String.valueOf(v);
	        
	        /*
	        if (s == null || s.trim().isEmpty()) {
	            v = js.executeScript("return arguments[0].textContent;", el);
	            s = v == null ? "" : String.valueOf(v);
	        }
	        */
	        // return s.isEmpty() ? null : s;
	        
	        return s;
	    } catch (StaleElementReferenceException ignore) {
	        log.info("3단계 - 데이터 추출중 에러남 삐~");
	    	return null;
	    }
	}

	/** 스크롤 로직 */
	private void scrollDown(WebDriver driver) {
		try {
			WebElement scrollYDiv = driver.findElement(SCROLL_Y);
			JavascriptExecutor js = (JavascriptExecutor) driver;
			
			// 현재 스크롤 위치 확인
			Long currentScrollTop = (Long) js.executeScript("return arguments[0].scrollTop;", scrollYDiv);

			// 스크롤 제어
			int scroll = 100; // 75:4, 100:5, (115,111):6, 160:8, 175:9
			long newScrollTop = currentScrollTop + scroll;
			js.executeScript("arguments[0].scrollTop = arguments[1];", scrollYDiv, newScrollTop);
		} catch (Exception e) {
			log.warn("3단계 - 세로 스크롤 제어");
		}
	}
	
	/** 펀드 고유 번호 추출 */
	private String extractStandardCode(WebDriver driver, WebDriverWait wait, WebElement row) {
	    String standardCode = null;
	    try {
	        // 1) 돋보기 아이콘 찾기
	        WebElement magnifierImg = findQuiet(row, COL_DETAIL_IMG);
	        if (magnifierImg == null) return null;

	        // 2) 클릭 (JS로 안정 클릭)
	        ((JavascriptExecutor) driver).executeScript("arguments[0].click();", magnifierImg);

	        // 3) iframe 전환(열릴 때까지 대기 후 자동 전환)
	        wait.until(ExpectedConditions.frameToBeAvailableAndSwitchToIt(IFRAME_BODY));

	        // 4) 로딩 팝업(있다면) 사라질 때까지 대기
	        try {
	            wait.until(ExpectedConditions.or(
	                    ExpectedConditions.invisibilityOfElementLocated(By.id("disLoadingPop")),
	                    ExpectedConditions.invisibilityOfElementLocated(By.id("loadingBox"))
	            ));
	        } catch (Exception ignore) { /* 로딩 요소가 없을 수도 있음 */ }

	        // 5) 코드 요소 대기 후 텍스트 추출
	        WebElement fundCodeEl = wait.until(ExpectedConditions.presenceOfElementLocated(FUND_CODE));
	        standardCode = getInnerText(driver, fundCodeEl);

	    } catch (Exception ex) {
	        log.warn("3단계 - 상세 모달에서 펀드 고유번호 추출 실패: {}", ex.getMessage());
	    } finally {
	        // 6) 언제든 프레임에서 빠져나오기
	        try { driver.switchTo().defaultContent(); } catch (Exception ignore) {}

	        // 7) 모달 닫기 버튼 클릭(있으면)
	        try {
	            WebElement closeBtn = findQuiet(driver, MODAL_CLOSE_BTN);
	            if (closeBtn != null) {
	                ((JavascriptExecutor) driver).executeScript("arguments[0].click();", closeBtn);
	                try { Thread.sleep(300); } catch (InterruptedException ignored) {}
	            }
	        } catch (Exception ignore) {
	            // 이미 닫혔거나 버튼이 다른 위치일 수 있음
	        }
	    }
	    return standardCode;
	}
}

/*

1. MVP(가시 행만): 로딩 끝 대기 → 현재 화면에 보이는 tr만 파싱 → ExecutionContext로 전달
2. 한 칸 스크롤 추가: 정확히 1행 내려가서 다음 가시 행 파싱(중복 방지)
3. 종료 조건/전체 루프: ALL_SEARCH_ITEM/MAX_SEARCH_ITEM 반영 + 끝 도달 판정
4. 모달/iframe 연동: 돋보기 클릭 → 고유번호 추출 → FundRowData.standardCode에 세팅
5. 견고성 보강: 오버레이/스테일 방어, 수평 스크롤 보정, 로그/타임아웃 다듬기
6. 정리: 성능/리팩터(원하면 헬퍼 분리)


정리된 권장 흐름
	1. 준비(대기)
		- 로딩 팝업이 사라질 때까지 기다린다. (disLoadingPop: display:none / visibility:hidden)
		- 테이블의 tbody가 존재할 때까지 기다린다. (최소 DOM 준비 확인)
		- “지금 보이는 행들”을 안정적으로 읽을 수 있음
	2. 현재 보이는 행(가시행) 읽기
		- 테이블에서 가시행만 가져오기
		- 각 행마다 핵심 필드를 읽는다
			- 운용사
			- 펀드명
			- 위험등급
			- 1/3/6/12개월 수익률
	3. 상한 체크
		- 지금까지 수집한 건수 fetched가 MAX_SEARCH_ROW에 도달했으면 즉시 종료
		- ALL_SEARCH_ITEM=true라면 이 단계는 건너뛰고 끝까지 간다
	4. 스크롤 “기준점” 저장
		- 스크롤하기 직전, 화면의 마지막 가시행의 키를 저장한다 → lastKeyBefore
			- 예: lastKeyBefore = "교보악사자산운용|어떤펀드A"
		- 이 값은 “스크롤 후 진짜로 새로운 영역으로 내려갔는지”를 판단하는 기준이 된다.
	5. 스크롤 제어
		- 그리드에 포커스를 주고 ↓(ArrowDown) 키를 보낸다. (가장 정확하게 1행)
		- 실패 대비: 
			- 키 입력이 안 먹히면, 세로 스크롤 컨테이너(grdMain_scrollY_div)의
			- scrollTop을 행 높이만큼(약 20~22px) JS로 살짝 올린다.
		- 아주 짧게(수십 ms) 잠깐 쉰다. (DOM 재렌더 타이밍)
	6. “진전했는지” 판단 (짧게 기다리며 확인)
		- 스크롤 직후 2가지 신호 중 하나라도 보이면 “진전 O”야.
		- 마지막 행 키가 바뀜
			- 방금 저장한 lastKeyBefore와, 지금 화면의 마지막 가시행 키가 다르면 새 영역으로 내려간 것.
		- 새로운 키가 보임
			- 현재 화면의 가시행 중에서, seen에 없는 키가 하나라도 등장하면 진전한 것.
		- 이 체크를 짧게(예: 0.3~3초) 폴링한다.
			- 진전 O → 다시 1번(대기) 로 돌아가 반복.
			- 진전 X → consecutiveNoNew++ (연속 카운트 증가)
				- 이게 2번(또는 3번) 연속이면 바닥 도달로 판단하고 종료.			




// 스크롤 설정
// private static final int FUNDS_PER_SCREEN = 9; // 한 화면에 보이는 펀드 수
// private static final int FUNDS_PER_SCROLL = 9; // 한 번 스크롤 시 새로 나타나는 펀드 수, 3
// private static final int MAX_SCROLL_LIMIT = 1; // 최대 스크롤 제한 (실용성), 200, 9
// private static final int SCROLL_DELAY_MS = 1500; // 스크롤 후 대기 시간





Selenium 표준 방식으로 보이는 텍스트를 안전하게 읽어오는 유틸. 
값이 비거나 <nobr> 안에만 있을 때를 보완.
private String safeText(WebElement el) {
	if (el == null)
		return null;
	try {
		String t = el.getText();
		if (t == null || t.isBlank()) {
			WebElement nobr = findQuiet(el, By.tagName("nobr"));
			if (nobr != null)
				t = nobr.getText();
		}
		return t == null ? null : t.trim();
	} catch (StaleElementReferenceException sere) {
		return null;
	}
}

private List<WebElement> findVisibleRows(WebDriver driver) {
	    return driver.findElements(VISIBLE_ROWS);
	}


1 단계
@Override
public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
	log.info("3단계 - CollectFundListTasklet - 테이블 데이터 조회");

	try {
		WebDriver driver = webDriverManager.getDriver();
		WebDriverWait wait = webDriverManager.getWait();

		wait.until(ExpectedConditions.invisibilityOfElementLocated(LOADINGPOPUP));
		wait.until(ExpectedConditions.presenceOfElementLocated(TBODY));

		List<WebElement> rows = driver.findElements(VISIBLE_ROWS);
		if (rows.isEmpty()) {
			log.warn("3단계 - 테이블에 데이터가 존재하지 않습니다");
		}

		List<FundRowData> out = new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();
        
        int fetched = 0;
        int consecutiveNoNew = 0; // 새 행 못 본 연속 횟수(바닥 감지용)
		int limit = Math.min(rows.size(), MAX_SEARCH_ROW);

		// 
		for (int i = 0; i < limit; i++) {
			WebElement row = rows.get(i);

		    String company  = getInnerText(driver, findQuiet(row, COL_COMPANY));
		    String fundName = getInnerText(driver, findQuiet(row, COL_FUND_NAME));
		    String risk     = getInnerText(driver, findQuiet(row, COL_RISK));
		    String ret1M    = getInnerText(driver, findQuiet(row, COL_RET_1M));
		    String ret3M    = getInnerText(driver, findQuiet(row, COL_RET_3M));
		    String ret6M    = getInnerText(driver, findQuiet(row, COL_RET_6M));
		    String ret12M   = getInnerText(driver, findQuiet(row, COL_RET_12M));
			
			FundRowData data = FundRowData.builder()
		            .company(company)
		            .fundName(fundName)
		            .riskRate(risk)
		            .ret1M(ret1M)
		            .ret3M(ret3M)
		            .ret6M(ret6M)
		            .ret12M(ret12M)
					.standardCode(null)			// 1단계에선 모달 안 들어감
		            .rowIndexSeen(i)
		            .rowKey(pickRowKey(row))	// 그대로 사용(원하면 company|fundName으로 바꿔도 됨)
		            .build();
			
			out.add(data);
		}

	} catch (Exception e) {
		log.error("❌ [3단계] 펀드 목록 수집 실패", e);
		throw e;
	}

	return RepeatStatus.FINISHED;
}




for (WebElement row : rows) {
    // 컬럼 읽기 (가시/비가시 모두 커버)
    String company  = getInnerText(driver, findQuiet(row, COL_COMPANY));
    String fundName = getInnerText(driver, findQuiet(row, COL_FUND_NAME));
    if ((company == null && fundName == null)) continue;
    
    // 중복 방지 키
    String key = ((company == null ? "" : company.trim()) + "|" + (fundName == null ? "" : fundName.trim()));
    if (key.equals("|") || seen.contains(key)) continue;
    
    String risk     = getInnerText(driver, findQuiet(row, COL_RISK));
    String ret1M    = getInnerText(driver, findQuiet(row, COL_RET_1M));
    String ret3M    = getInnerText(driver, findQuiet(row, COL_RET_3M));
    String ret6M    = getInnerText(driver, findQuiet(row, COL_RET_6M));
    String ret12M   = getInnerText(driver, findQuiet(row, COL_RET_12M));

    FundRowData data = FundRowData.builder()
            .company(company)
            .fundName(fundName)
            .riskRate(risk)
            .ret1M(ret1M)
            .ret3M(ret3M)
            .ret6M(ret6M)
            .ret12M(ret12M)
            .standardCode(null) 
            // .rowIndexSeen(fetched)
            // .rowKey(key) // pickRowKey(row) 대신, 방금 읽은 값으로 일관성 있게
            .build();
    out.add(data);
    seen.add(key);
    fetched++;
    
    // 수집 상한
    if (fetched >= MAX_SEARCH_ROW) {
        log.info("3단계 - MAX_SEARCH_ROW({}) 도달, 종료", MAX_SEARCH_ROW);
        break;
    }
}




=============================================================



// 메인 루프: 보이는 행 → 수집 → 한 칸 스크롤 → 진전 여부 확인
while (true) {
    //List<WebElement> rows = findVisibleRows(driver);
	List<WebElement> rows = driver.findElements(By.cssSelector("tr.grid_body_row:not(.w2grid_hidedRow):not([style*='display: none'])"));
	
	if (rows.isEmpty()) {
		log.warn("3단계 - 테이블에 데이터가 존재하지 않습니다");
	}

    for (WebElement row : rows) {
        // 컬럼 읽기 
        String fundName = getInnerText(driver, findQuiet(row, COL_FUND_NAME));
        String risk     = getInnerText(driver, findQuiet(row, COL_RISK));
        String ret1M    = getInnerText(driver, findQuiet(row, COL_RET_1M));
        String ret3M    = getInnerText(driver, findQuiet(row, COL_RET_3M));
        String ret6M    = getInnerText(driver, findQuiet(row, COL_RET_6M));
        String ret12M   = getInnerText(driver, findQuiet(row, COL_RET_12M));

        fundName = (fundName == null) ? null : fundName.replace('\u00A0', ' ').replaceAll("\\s+", " ").trim();
        if (fundName == null || fundName.isEmpty()) continue;
        if (!seen.add(fundName)) continue;

        FundRowData data = FundRowData.builder()
                .standardCode(null) 
                .fundName(fundName)
                .riskRate(risk)
                .ret1M(ret1M)
                .ret3M(ret3M)
                .ret6M(ret6M)
                .ret12M(ret12M)
                .build();
        out.add(data);
        // fetched++;

        // 상한 도달 시 끊기
        if (!ALL_SEARCH_ROW && out.size() >= MAX_SEARCH_ROW) break;
    }

    if (fetched >= MAX_SEARCH_ROW) break;
    
    // 3) 한 칸 스크롤 → 진전했는지 확인
    String lastKeyBefore = getLastVisibleRowKey(driver); // 스크롤 전 마지막 행 키
    boolean scrolled = scrollDownOneRow(driver, wait);
    if (!scrolled) {
        log.info("3단계 - 더 이상 스크롤할 수 없습니다. 종료");
        break;
    }
    
    boolean progressed = waitUntilNewRowsOrNewKey(driver, wait, lastKeyBefore, seen);
    if (!progressed) {
        consecutiveNoNew++;
        log.info("3단계 - 스크롤했지만 새 행이 보이지 않음 ({}회 연속)", consecutiveNoNew);
        if (consecutiveNoNew >= 2) { // 두 번 연속 진전 없으면 바닥으로 간주
            log.info("3단계 - 진전 없음이 연속으로 발생 → 바닥 도달 추정, 종료");
            break;
        }
    } else {
        consecutiveNoNew = 0;
    }
}

log.info("3단계 - 수집 완료: {}건", out.size());
for(FundRowData item : out) {
	System.out.println(item);
}
return RepeatStatus.FINISHED;



*/  
