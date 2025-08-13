package com.example.batch_scraper.job;

import org.springframework.batch.core.Job;
import org.springframework.batch.core.job.builder.FlowBuilder;
import org.springframework.batch.core.job.builder.JobBuilder;
import org.springframework.batch.core.job.flow.Flow;
import org.springframework.batch.core.launch.support.RunIdIncrementer;
import org.springframework.batch.core.repository.JobRepository;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.example.batch_scraper.job.step.BrowserInitStep;
import com.example.batch_scraper.job.step.CleanupStep;
import com.example.batch_scraper.job.step.FundDetailScrapingStep;
import com.example.batch_scraper.job.step.FundListCollectStep;
import com.example.batch_scraper.job.step.SearchConditionStep;
import com.example.batch_scraper.selenium.WebDriverJobListener;

import lombok.RequiredArgsConstructor;

@Configuration
@RequiredArgsConstructor
public class JobConfig {

	private final JobRepository jobRepository;
    private final WebDriverJobListener webDriverJobListener;

	private final BrowserInitStep browserInitStep;
	private final SearchConditionStep searchConditionStep;
	private final FundListCollectStep fundListCollectStep;
	private final FundDetailScrapingStep fundDetailScrapingStep;
	private final CleanupStep cleanupStep;

	@Bean
    public Job fundScrapingJob() {
        return new JobBuilder("fundScrapingJob", jobRepository)
                .incrementer(new RunIdIncrementer())
                .listener(webDriverJobListener)
                .start(browserInitStep.createStep())
                .next(searchConditionStep.createStep())
                .next(fundListCollectStep.createStep())
                .next(fundDetailScrapingStep.createStep())
                .next(cleanupStep.createStep())
                .build();
    }
	
}

/*


@Bean
public Job fundScrapingJob() {
    return new JobBuilder("fundScrapingJob", jobRepository)
        .incrementer(new RunIdIncrementer())
        .listener(webDriverJobListener)
        .start(createMainFlow())
        .end()
        .build();
}

private Flow createMainFlow() {
    return new FlowBuilder<Flow>("mainProcessingFlow")
        .start(browserInitStep.createStep())
            .on("FAILED").to(cleanupStep.createStep())
        .from(browserInitStep.createStep())
            .on("*").to(searchConditionStep.createStep())
        .from(searchConditionStep.createStep())
            .on("FAILED").to(cleanupStep.createStep())
            .on("*").to(fundListCollectStep.createStep())
        .from(fundListCollectStep.createStep())
            .on("FAILED").to(cleanupStep.createStep())
            .on("*").to(fundDetailScrapingStep.createStep())
        .from(fundDetailScrapingStep.createStep())
            .on("*").to(cleanupStep.createStep())
        .end();
}


@Bean
	public Job fundScrapingJob() {
	    final var init    = browserInitStep.createStep();
	    final var search  = searchConditionStep.createStep();
	    final var list    = fundListCollectStep.createStep();
	    final var detail  = fundDetailScrapingStep.createStep();
	    final var cleanup = cleanupStep.createStep(); // 내부에서 allowStartIfComplete(true) 권장

	    return new JobBuilder("fundScrapingJob", jobRepository)
	    		.incrementer(new RunIdIncrementer())
		        .listener(webDriverJobListener)
		        .start(init).on("FAILED").to(cleanup)
		        .from(init).on("*").to(search)
		        .from(search).on("FAILED").to(cleanup)
		        .from(search).on("*").to(list)
		        .from(list).on("FAILED").to(cleanup)
		        .from(list).on("*").to(detail)
		        .from(detail).on("*").to(cleanup)
		        .end()      // FlowJobBuilder를 JobFlowBuilder로 변환
		        .build();   // Job 반환
	}


*/  
