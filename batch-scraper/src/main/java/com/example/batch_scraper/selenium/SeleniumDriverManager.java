package com.example.batch_scraper.selenium;


import java.time.Duration;
import java.util.concurrent.locks.ReentrantLock;

import org.openqa.selenium.WebDriver;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.chrome.ChromeOptions;
import org.openqa.selenium.support.ui.WebDriverWait;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;

/**
 * WebDriver 생명주기 관리
 * Job 실행 동안 하나의 WebDriver 인스턴스를 모든 Step에서 공유
 */
@Component
@Slf4j
public class SeleniumDriverManager {
    // --- 외부 설정 주입 (application.yml) ---
    @Value("${selenium.headless:false}")
    private boolean headless;

    @Value("${selenium.window.width:1920}")
    private int windowWidth;

    @Value("${selenium.window.height:1080}")
    private int windowHeight;

    @Value("${selenium.timeouts.page-load-sec:60}")
    private int pageLoadTimeoutSec;
    
    @Value("${selenium.timeouts.explicit-sec:30}")
    private int explicitWaitSec;

    @Value("${selenium.timeouts.implicit-sec:0}")	// 암묵적 대기는 0 권장 (혼용 시 예측 불가)
    private int implicitWaitSec;
    
    // @Value("${selenium.target-url}")
    // private String targetUrl;
    
    // --- 상태 ---
    private final ReentrantLock lock = new ReentrantLock();
    private volatile WebDriver driver;
    private volatile WebDriverWait wait;
    private volatile boolean initialized = false;
    
    /** 드라이버 초기화 (동시 실행 보호) */
    public void initializeDriver() {
    	if (initialized && driver != null) {
            log.info("SeleniumDriverManager - WebDriver 이미 초기화됨");
            return;
        }
        lock.lock();
    	
        try {
            if (initialized && driver != null) return;

            ChromeOptions options = createChromeOptions();
            this.driver = new ChromeDriver(options);

            // 타임아웃 설정
            driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(implicitWaitSec));
            driver.manage().timeouts().pageLoadTimeout(Duration.ofSeconds(pageLoadTimeoutSec));

            this.wait = new WebDriverWait(driver, Duration.ofSeconds(explicitWaitSec));
            this.initialized = true;

    	} catch (Exception e) {
            log.error("WebDriver 초기화 실패", e);
            closeDriver(); // 실패 시 정리
            throw new IllegalStateException("WebDriver 초기화 실패", e);
        } finally {
            lock.unlock();
        }
    	
    }
    
    /** 크롬 옵션 */
    private ChromeOptions createChromeOptions() {
        ChromeOptions options = new ChromeOptions();

        if (headless) {
            // 신규 헤드리스 파이프라인
            options.addArguments("--headless=new");
        }

        // 기본 옵션
        options.addArguments("--no-sandbox");
        options.addArguments("--disable-dev-shm-usage");
        options.addArguments("--disable-gpu");
        options.addArguments(String.format("--window-size=%d,%d", windowWidth, windowHeight));
        options.addArguments("--force-device-scale-factor=1.0"); 

        options.setExperimentalOption("useAutomationExtension", false);
        options.setExperimentalOption("excludeSwitches", new String[]{"enable-automation"});
        
        return options;
    }
    
    /** 드라이버 가져오기 */
    public WebDriver getDriver() {
        if (!initialized || driver == null) {
            throw new IllegalStateException("WebDriver 미초기화. initializeDriver() 먼저 호출하세요.");
        }
        return driver;
    }
    
    /** WebDriverWait 가져오기 */
    public WebDriverWait getWait() {
        if (!initialized || wait == null) {
            throw new IllegalStateException("WebDriver 미초기화. initializeDriver() 먼저 호출하세요.");
        }
        return wait;
    }
    
    /** 현재 URL */
    public String getCurrentUrl() {
        return (initialized && driver != null) ? driver.getCurrentUrl() : null;
    }
    
    /** 새로고침 */
    public void refresh() {
        if (initialized && driver != null) {
            log.info("🔄 페이지 새로고침");
            driver.navigate().refresh();
        }
    }
    
    /** 타겟 URL 반환 */
//    public String getTargetUrl() {
//        if (targetUrl == null || targetUrl.isBlank())
//            throw new IllegalStateException("selenium.target-url 미설정");
//        return targetUrl;
//    }
    
    /** 종료 메서드 */
    public void closeDriver() {
        lock.lock();
        try {
            initialized = false; // 먼저 플래그를 false로
            
            if (driver != null) {
                try {
                    log.info("WebDriver 종료 중...");
                    driver.quit();
                    log.info("WebDriver 종료 완료");
                } catch (Exception e) {
                    log.warn("WebDriver 종료 중 오류", e);
                } finally {
                    driver = null;
                    wait = null;
                }
            }
        } finally {
            lock.unlock();
        }
    }

    /** 초기화 여부 */
    public boolean isInitialized() {
        return initialized && driver != null;
    }
    

    /** 앱 종료 시 정리 */
    @PreDestroy
    public void cleanup() {
        log.info("애플리케이션 종료 - WebDriver 정리");
        closeDriver();
    }
}

