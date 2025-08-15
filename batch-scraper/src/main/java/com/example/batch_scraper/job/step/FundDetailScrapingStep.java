package com.example.batch_scraper.job.step;

import org.springframework.batch.core.Step;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.batch.core.step.builder.StepBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.core.task.TaskExecutor;
import org.springframework.scheduling.concurrent.ThreadPoolTaskExecutor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.PlatformTransactionManager;

import com.example.batch_scraper.dto.CompleteFundData;
import com.example.batch_scraper.dto.FundRowData;
import com.example.batch_scraper.job.chunk.FundDataWriter;
import com.example.batch_scraper.job.chunk.FundDetailProcessor;
import com.example.batch_scraper.job.chunk.FundListReader;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class FundDetailScrapingStep {
    
    private final JobRepository jobRepository;
    private final PlatformTransactionManager transactionManager;
    
    // Chunk 구성 요소들
    private final FundListReader fundListReader;
    private final FundDetailProcessor fundDetailProcessor;
    private final FundDataWriter fundDataWriter;
    
    public TaskExecutor batchTaskExecutor() {
        ThreadPoolTaskExecutor exec = new ThreadPoolTaskExecutor();
        exec.setCorePoolSize(4);
        exec.setMaxPoolSize(4);
        exec.setQueueCapacity(0);
        exec.initialize();
        return exec;
    }
    
    public Step createStep() {
        return new StepBuilder("scrapeFundDetailsStep", jobRepository)
                .<FundRowData, CompleteFundData>chunk(5, transactionManager) 
                .reader(fundListReader)           
                .processor(fundDetailProcessor)   
                .writer(fundDataWriter)
                // .taskExecutor(batchTaskExecutor()) // Spring Batch 5에서부터 TaskExecutor 자체에서 스레드 수 제어
                //.throttleLimit(4)					// deprecated 됨
                .build();
    }
}