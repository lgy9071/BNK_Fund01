package com.example.batch_scraper.job.tasklet;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.batch.core.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.selenium.SeleniumDriverManager;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 2단계: 검색 조건 설정
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class SetupSearchConditionsTasklet implements Tasklet {
    
    private final SeleniumDriverManager webDriverManager;
    
    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) throws Exception {
        log.info("2단계 - SetupSearchConditionsTasklet - 검색 조건 설정");
        
        try {
            WebDriver driver = webDriverManager.getDriver();
            WebDriverWait wait = webDriverManager.getWait();

            // 수익률 구간 체크박스 설정
            log.info("2단계 - 수익률 구간 체크박스 설정 중...");
            setCheckbox(wait, By.id("listCheck_input_0"), true, "1개월");  // 1M
            setCheckbox(wait, By.id("listCheck_input_1"), true, "3개월");  // 3M
            setCheckbox(wait, By.id("listCheck_input_2"), true, "6개월");  // 6M
            setCheckbox(wait, By.id("listCheck_input_4"), true, "1년");    // 1Y
            setCheckbox(wait, By.id("listCheck_input_10"), false, "설정(전환)일");

            // 검색 버튼 클릭
            log.info("2단계 - 검색 실행 중...");
            WebElement searchBtn = wait.until(ExpectedConditions.elementToBeClickable(By.id("image18")));
            // scrollIntoView(driver, searchBtn);
            searchBtn.click();
            log.info("2단계 - 검색 버튼 클릭 완료");

            log.info("2단계 - 검색 결과 로딩 대기 중...");
            wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("disLoadingPop")));
            Thread.sleep(5000);	// 불안정해서 고정값 만큼 대기

            log.info("2단계 - 검색 결과 로딩 완료");
            return RepeatStatus.FINISHED;
        } catch (Exception e) {
            log.error("❌ [2단계] 검색 조건 설정 실패", e);
            throw e;
        }
    }
    
    
    /** 체크박스를 원하는 상태로 맞춘다 (true=체크, false=해제). */
    private void setCheckbox(WebDriverWait wait, By by, boolean shouldBeSelected, String labelForLog) {
        try {
            WebElement cb = wait.until(ExpectedConditions.presenceOfElementLocated(by));
            // scrollIntoView(wait.getClock().withTimeout(null) == null ? null : (WebDriver) ((WrapsDriver) cb).getWrappedDriver(), cb); // 안전 스크롤 (드라이버 얻기 어려우면 호출부에서 드라이버 넘겨줘도 됨)
            wait.until(ExpectedConditions.elementToBeClickable(cb));

            boolean current = cb.isSelected();
            if (current != shouldBeSelected) {
                cb.click();
                log.info("2단계 - {} 체크박스 {}", labelForLog, shouldBeSelected ? "활성화" : "해제");
            } else {
                log.info("2단계 - {} 체크박스 이미 {}", labelForLog, shouldBeSelected ? "활성화됨" : "해제됨");
            }
        } catch (Exception e) {
            log.warn("2단계 - {} 체크박스 처리 실패: {}", labelForLog, e.getMessage());
        }
    }
    
    /** 클릭 전에 가시 영역으로 가져오면 Intercepted/NotInteractable 방지에 도움. */
    private void scrollIntoView(WebDriver driver, WebElement el) {
        try {
            if (driver instanceof JavascriptExecutor) {
                ((JavascriptExecutor) driver).executeScript("arguments[0].scrollIntoView({block: 'center'});", el);
            }
        } catch (Exception ignore) {}
    }
    
    /** 속성 기반으로 확실한 로딩 대기 */
    private void waitForLoadingOff(WebDriver driver, WebDriverWait wait) {
        By overlay = By.id("disLoadingPop");
        wait.until(d -> {
            try {
                WebElement el = d.findElement(overlay);
                // 1) 표준 가시성
                if (!el.isDisplayed()) return true;

                // 2) aria-hidden
                String aria = el.getAttribute("aria-hidden");
                if ("true".equalsIgnoreCase(aria)) return true;

                // 3) style 값 검사(display/visibility)
                String style = (el.getAttribute("style") + "").replace(" ", "").toLowerCase();
                boolean displayNone = style.contains("display:none");
                boolean visibilityHidden = style.contains("visibility:hidden");
                return displayNone || visibilityHidden;
            } catch (NoSuchElementException e) {
                // DOM에서 제거됨 == 숨김
                return true;
            }
        });
    }
}