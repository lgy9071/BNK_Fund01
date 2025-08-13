package com.example.batch_scraper.selenium;


import java.time.Duration;
import java.util.List;

import org.openqa.selenium.By;
import org.openqa.selenium.JavascriptExecutor;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.support.ui.ExpectedConditions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.stereotype.Component;

import lombok.extern.slf4j.Slf4j;

/**
 * Selenium 공통 유틸리티
 */
@Component
@Slf4j
public class SeleniumUtils {
    
    /**
     * 안전한 요소 클릭 (재시도 포함)
     */
    public void safeClick(WebDriver driver, By locator, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        
        try {
            // 요소가 클릭 가능할 때까지 대기
            WebElement element = wait.until(ExpectedConditions.elementToBeClickable(locator));
            
            // 요소가 화면에 보이도록 스크롤
            scrollToElement(driver, element);
            
            // 클릭 시도
            element.click();
            log.debug("요소 클릭 성공: {}", locator);
            
        } catch (Exception e) {
            log.warn("일반 클릭 실패, JavaScript 클릭 시도: {}", locator);
            try {
                // JavaScript로 클릭 시도
                WebElement element = driver.findElement(locator);
                JavascriptExecutor js = (JavascriptExecutor) driver;
                js.executeScript("arguments[0].click();", element);
                log.debug("JavaScript 클릭 성공: {}", locator);
            } catch (Exception jsException) {
                log.error("JavaScript 클릭도 실패: {}", locator, jsException);
                throw new RuntimeException("요소 클릭 실패: " + locator, jsException);
            }
        }
    }
    
    /**
     * 안전한 텍스트 입력
     */
    public void safeInput(WebDriver driver, By locator, String text, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        
        try {
            WebElement element = wait.until(ExpectedConditions.presenceOfElementLocated(locator));
            element.clear();
            element.sendKeys(text);
            log.debug("텍스트 입력 성공: {} = '{}'", locator, text);
        } catch (Exception e) {
            log.error("텍스트 입력 실패: {}", locator, e);
            throw new RuntimeException("텍스트 입력 실패: " + locator, e);
        }
    }
    
    /**
     * 안전한 텍스트 추출
     */
    public String safeGetText(WebDriver driver, By locator, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        
        try {
            WebElement element = wait.until(ExpectedConditions.presenceOfElementLocated(locator));
            String text = element.getText().trim();
            log.debug("텍스트 추출 성공: {} = '{}'", locator, text);
            return text;
        } catch (Exception e) {
            log.warn("텍스트 추출 실패: {}", locator, e);
            return "";
        }
    }
    
    /**
     * 요소까지 스크롤
     */
    public void scrollToElement(WebDriver driver, WebElement element) {
        try {
            JavascriptExecutor js = (JavascriptExecutor) driver;
            js.executeScript("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", element);
            Thread.sleep(500); // 스크롤 완료 대기
        } catch (Exception e) {
            log.warn("스크롤 실패", e);
        }
    }
    
    /**
     * 페이지 최상단으로 스크롤
     */
    public void scrollToTop(WebDriver driver) {
        try {
            JavascriptExecutor js = (JavascriptExecutor) driver;
            js.executeScript("window.scrollTo(0, 0);");
            Thread.sleep(500);
        } catch (Exception e) {
            log.warn("최상단 스크롤 실패", e);
        }
    }
    
    /**
     * 테이블 행 개수 가져오기
     */
    public int getTableRowCount(WebDriver driver, By tableLocator, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        
        try {
            wait.until(ExpectedConditions.presenceOfElementLocated(tableLocator));
            List<WebElement> rows = driver.findElements(By.cssSelector(tableLocator.toString() + " tbody tr"));
            log.debug("테이블 행 개수: {}", rows.size());
            return rows.size();
        } catch (Exception e) {
            log.error("테이블 행 개수 조회 실패: {}", tableLocator, e);
            return 0;
        }
    }
    
    /**
     * iframe으로 전환
     */
    public void switchToIframe(WebDriver driver, By iframeLocator, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        
        try {
            WebElement iframe = wait.until(ExpectedConditions.presenceOfElementLocated(iframeLocator));
            driver.switchTo().frame(iframe);
            log.debug("iframe 전환 성공: {}", iframeLocator);
        } catch (Exception e) {
            log.error("iframe 전환 실패: {}", iframeLocator, e);
            throw new RuntimeException("iframe 전환 실패: " + iframeLocator, e);
        }
    }
    
    /**
     * 기본 프레임으로 복귀
     */
    public void switchToDefaultContent(WebDriver driver) {
        try {
            driver.switchTo().defaultContent();
            log.debug("기본 프레임으로 복귀 성공");
        } catch (Exception e) {
            log.error("기본 프레임 복귀 실패", e);
        }
    }
    
    /**
     * 페이지 로딩 완료 대기
     */
    public void waitForPageLoad(WebDriver driver, int timeoutSeconds) {
        WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(timeoutSeconds));
        
        try {
            wait.until(webDriver -> {
                JavascriptExecutor js = (JavascriptExecutor) webDriver;
                return js.executeScript("return document.readyState").equals("complete");
            });
            log.debug("페이지 로딩 완료");
        } catch (Exception e) {
            log.warn("페이지 로딩 대기 타임아웃", e);
        }
    }
    
    /**
     * 지정된 시간만큼 대기
     */
    public void sleep(long milliseconds) {
        try {
            Thread.sleep(milliseconds);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.warn("대기 중 인터럽트 발생", e);
        }
    }
}