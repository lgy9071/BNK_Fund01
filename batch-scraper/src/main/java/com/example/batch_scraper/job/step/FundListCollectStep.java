package com.example.batch_scraper.job.step;

import org.springframework.batch.core.Step;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import com.example.batch_scraper.job.tasklet.CollectFundListTasklet;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class FundListCollectStep {
    
    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    private final CollectFundListTasklet collectFundListTasklet;
    
    /**
     * 3단계: 펀드 목록 수집 Step 생성
     */
    public Step createStep() {
        return new StepBuilder("collectFundListStep", jobRepository)
                .tasklet(collectFundListTasklet, transactionManager)
                .build();
    }
}