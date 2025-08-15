package com.example.batch_scraper.job.step;

import org.springframework.batch.core.Step;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import com.example.batch_scraper.job.tasklet.SetupSearchConditionsTasklet;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class SearchConditionStep {
    
    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    private final SetupSearchConditionsTasklet setupSearchConditionsTasklet;
    
    /**
     * 2단계: 검색 조건 설정 Step 생성
     */
    public Step createStep() {
        return new StepBuilder("setupSearchConditionsStep", jobRepository)
                .tasklet(setupSearchConditionsTasklet, transactionManager)
                .build();
    }
}