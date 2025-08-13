package com.example.batch_scraper.job.tasklet;

import org.springframework.batch.core.StepContribution;
import org.springframework.batch.core.scope.context.ChunkContext;
import org.springframework.batch.core.step.tasklet.Tasklet;
import org.springframework.batch.repeat.RepeatStatus;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.selenium.SeleniumDriverManager;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * 5단계: 리소스 정리
 *  - WebDriver 인스턴스 종료만 수행
 */
@Component
@RequiredArgsConstructor
@Slf4j
public class CleanupTasklet implements Tasklet {

    private final SeleniumDriverManager webDriverManager;   // WebDriver 관리 Bean 주입

    @Override
    public RepeatStatus execute(StepContribution contribution, ChunkContext chunkContext) {

        log.info("5단계 - CleanupTasklet: WebDriver 정리 시작");
        webDriverManager.closeDriver();     // null·중복 호출 안전
        log.info("5단계 - CleanupTasklet: WebDriver 정리 완료");

        return RepeatStatus.FINISHED;
    }
}