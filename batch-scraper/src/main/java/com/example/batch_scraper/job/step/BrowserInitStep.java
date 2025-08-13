package com.example.batch_scraper.job.step;

import org.springframework.batch.core.Step;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import com.example.batch_scraper.job.tasklet.InitializeBrowserTasklet;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class BrowserInitStep {
    
    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    private final InitializeBrowserTasklet initializeBrowserTasklet;
    /**
     * 1단계: 브라우저 초기화 Step 생성
     */
    public Step createStep() {
        return new StepBuilder("initializeBrowserStep", jobRepository)
                .tasklet(initializeBrowserTasklet, transactionManager)
                .build();
    }
}