package com.example.batch_scraper.selenium;

import org.springframework.batch.core.JobExecution;
import org.springframework.batch.core.JobExecutionListener;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@RequiredArgsConstructor
public class WebDriverJobListener implements JobExecutionListener {

    private final SeleniumDriverManager driverManager;
    
    @Override
    public void beforeJob(JobExecution jobExecution) {
        log.info("시작전 - beforeJob - WebDriverJobListener");
        // 드라이버를 여기서 항상 키고 싶다면:
        // if (!driverManager.isInitialized()) driverManager.initializeDriver();
    }

    @Override
    public void afterJob(JobExecution jobExecution) {
        log.info("afterJob - WebDriverJobListener");
        driverManager.closeDriver(); // 항상 정리
    }
    
}

/*

// 예시(간단 버전): 마지막 단계 전에서 무조건 cleanupStep 실행
var s1 = browserInitStep.createStep();
var s2 = searchConditionStep.createStep();
var s3 = fundListCollectStep.createStep();
var s4 = fundDetailScrapingStep.createStep();
var sc = cleanupStep.createStep();

return new JobBuilder("fundScrapingJob", jobRepository)
        .incrementer(new RunIdIncrementer())
        .listener(webDriverCleanupListener)
        .start(s1).on("*").to(s2)
        .from(s2).on("*").to(s3)
        .from(s3).on("*").to(s4)
        .from(s4).on("*").to(sc)           // ✅ 어떤 상태든 마무리 단계로
        .end()
        .build();

*/