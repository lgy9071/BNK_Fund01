package com.example.batch_scraper.scheduler;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.example.batch_scraper.job.JobRunner;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;


/**
 * 배치 작업의 실행 스케줄 관리
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class BatchScheduler {

    private final JobRunner jobRunner;

    /** 매일 18:00 (Asia/Seoul) */
    @Scheduled(cron = "0 0 18 * * *", zone = "Asia/Seoul")
    public void runScheduledJob() {
        try {
            jobRunner.safeRun("schedule");
        } catch (Exception e) {
            log.error("❌ 스케줄 Job 실행 실패", e);
        }
    }

}


// cron 표현식: "초 분 시 일 월 요일"
// "0 0 10 * * ?" = 매일 오전 10시 00분 00초