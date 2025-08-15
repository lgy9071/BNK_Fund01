package com.example.batch_scraper.job.tasklet;

import java.time.Duration;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.TimeoutException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebDriverException;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.batch.core.StepContribution;
import org.springframework.batch.core.configuration.annotation.StepScope;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.selenium.SeleniumDriverManager;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Step 1: 브라우저 초기화
 */
@Slf4j
@Component
@StepScope
@RequiredArgsConstructor
public class InitializeBrowserTasklet implements Tasklet {
	private final SeleniumDriverManager webDriverManager;

	private static final int MAX_RETRY_COUNT = 3;
	private static final int RETRY_DELAY_MS = 5000;
	private static final int PAGE_LOAD_TIMEOUT_SECONDS = 30;
	private static final int DOCUMENT_READY_TIMEOUT_SECONDS = 30;
	
	@Override
	public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
		log.info("1단계 - InitializeBrowserTasklet - 브라우저 초기화");

		try {
			// ⭐ WebDriver 초기화 (최초 1번만)
			webDriverManager.initializeDriver();
			WebDriver driver = webDriverManager.getDriver();
			WebDriverWait wait = webDriverManager.getWait();

			// 대상 URL 결정
			String targetUrl = "https://dis.kofia.or.kr/websquare/index.jsp?w2xPath=/wq/fundann/DISFundROPCmpAnn.xml&divisionId=MDIS01009001000000&serviceId=SDIS01009001000";
			
			// 재시도 로직으로 페이지 로드
			boolean pageLoadSuccess = loadPage(driver, wait, targetUrl);
			
			if (!pageLoadSuccess) {
				throw new Exception("페이지 로드에 실패했습니다. 최대 재시도 횟수를 초과했습니다.");
			}

			log.info("1단계 - 브라우저 초기화 완료");
			return RepeatStatus.FINISHED;

		} catch (Exception e) {
			log.error("1단계 - 브라우저 초기화 실패: {}", e);
			webDriverManager.closeDriver();
			throw new Exception("브라우저 초기화 실패", e);
		} 
	}
	
	/** 페이지 로드 + 재시도 로직 */
	private boolean loadPage(WebDriver driver, WebDriverWait wait, String targetUrl) {
		for(int attempt = 1; attempt <= MAX_RETRY_COUNT; attempt++) {
			try {
				log.info("1단계 - 사이트 접속 시도 {}/{}", attempt, MAX_RETRY_COUNT);
				
				// 페이지 로드
				driver.get(targetUrl);
				
				// 페이지 로딩 상태 검증
				if (validatePageLoad(driver, wait)) {
					log.info("1단계 - 페이지 로드 성공 (시도: {})", attempt);
					return true;
				} else {
					log.warn("1단계 - 페이지 로드 검증 실패 (시도: {})", attempt);
					handleFailedAttempt(driver, attempt);
				}
				
			} catch (TimeoutException e) {
				log.warn("1단계 - 페이지 로드 타임아웃 (시도: {}): {}", attempt, e.getMessage());
				handleFailedAttempt(driver, attempt);
				
			} catch (WebDriverException e) {
				log.warn("1단계 - WebDriver 예외 (시도: {}): {}", attempt, e.getMessage());
				handleFailedAttempt(driver, attempt);
				
			} catch (Exception e) {
				log.warn("1단계 - 일반 예외 (시도: {}): {}", attempt, e.getMessage());
				handleFailedAttempt(driver, attempt);
			}
		}
		
		return false;
	}
	
	/** 페이지 로드 상태 판별 */
	private boolean validatePageLoad(WebDriver driver, WebDriverWait wait) {
		try {
			// 문서 준비 검증
			waitUntilDocumentReady(driver);

			// 페이지 구조 검증
			if (!isPageStructureValid(driver)) {
				return false;
			}

			return true;
		} catch (Exception e) {
			log.warn("페이지 로딩 검증 중 예외 발생: {}", e.getMessage());
			return false;
		}
	}

	/** 페이지 기본 구조 검증 */
	private boolean isPageStructureValid(WebDriver driver) {
		try {
			// body 태그 존재 확인
			WebElement body = driver.findElement(By.tagName("body"));
			if (body == null) {
				log.warn("body 태그를 찾을 수 없습니다");
				return false;
			}
			
			// body 내용 확인
			String bodyText = body.getText().trim();
			if (bodyText.isEmpty()) {
				log.warn("body 태그 내용이 비어있습니다");
				return false;
			}

			return true;
		} catch (NoSuchElementException e) {
			log.warn("필수 페이지 요소를 찾을 수 없습니다: {}", e.getMessage());
			return false;
		} catch (Exception e) {
			log.warn("페이지 구조 검증 중 예외 발생: {}", e.getMessage());
			return false;
		}
		
	}
	
	/** js 로딩 상태 확인 */
	private void waitUntilDocumentReady(WebDriver driver) {
		// wait.until(d -> "complete".equals(((JavascriptExecutor) d).executeScript("return document.readyState")));
		
		try {
			WebDriverWait documentWait = new WebDriverWait(driver, Duration.ofSeconds(DOCUMENT_READY_TIMEOUT_SECONDS));
			documentWait.until(d -> {
				String readyState = (String) ((JavascriptExecutor) d)
					.executeScript("return document.readyState");
				log.debug("Document ready state: {}", readyState);
				return "complete".equals(readyState);
			});
		} catch (TimeoutException e) {
			log.warn("1단계 - 문서 준비 상태 확인 타임아웃: {}", e.getMessage());
		}
	}
	
	/** 실패한 시도 후 처리 */
	private void handleFailedAttempt(WebDriver driver, int attempt) {
		if (attempt < MAX_RETRY_COUNT) {
			try {
				log.info("1단계 - {}ms 후 재시도합니다...", RETRY_DELAY_MS);
				Thread.sleep(RETRY_DELAY_MS);
				
				// 페이지 새로고침 시도
				log.info("1단계 - 페이지 새로고침 시도");
				driver.navigate().refresh();
				Thread.sleep(2000);
				
			} catch (InterruptedException e) {
				Thread.currentThread().interrupt();
				log.warn("대기 중 인터럽트 발생");
			} catch (Exception e) {
				log.warn("재시도 준비 중 예외 발생: {}", e.getMessage());
			}
		}
	}


	private void safeClose() {
		webDriverManager.closeDriver();
	}
}


//@Override
//public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
//	log.info("1단계 - InitializeBrowserTasklet - 브라우저 초기화");
//
//	try {
//		// ⭐ WebDriver 초기화 (최초 1번만)
//		webDriverManager.initializeDriver();
//		WebDriver driver = webDriverManager.getDriver();
//		WebDriverWait wait = webDriverManager.getWait();
//
//		// 대상 URL 결정
//		String targetUrl = "https://dis.kofia.or.kr/websquare/index.jsp?w2xPath=/wq/fundann/DISFundROPCmpAnn.xml&divisionId=MDIS01009001000000&serviceId=SDIS01009001000";
//		log.info("1단계 - 사이트 접속");
//		driver.get(targetUrl);
//
//		// 문서 준비 상태 체크(선택) + 핵심 엘리먼트 기준 대기
//		waitUntilDocumentReady(wait);
//
//		log.info("1단계 - 브라우저 초기화 완료");
//		contribution.setExitStatus(ExitStatus.COMPLETED);
//		Thread.sleep(5000);
//		
//		return RepeatStatus.FINISHED;
//
//	} catch (Exception e) {
//		log.error("1단계 - 브라우저 초기화 실패: {}", e);
//		throw new Exception("브라우저 초기화 실패", e);
//	} finally {
//		if (!ExitStatus.COMPLETED.equals(contribution.getExitStatus())) {
//			safeClose();
//		}
//	}
//}