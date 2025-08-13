package com.example.batch_scraper.job.step;

import org.springframework.batch.core.Step;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import com.example.batch_scraper.job.tasklet.CleanupTasklet;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class CleanupStep {
    
    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    private final CleanupTasklet cleanupAndNotifyTasklet;
    
    /**
     * 5단계: 정리  Step 생성
     */
    public Step createStep() {
        return new StepBuilder("cleanupAndNotifyStep", jobRepository)
                .tasklet(cleanupAndNotifyTasklet, transactionManager)
                .build();
    }
}