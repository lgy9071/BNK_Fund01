package com.example.batch_scraper;

import org.springframework.batch.core.configuration.annotation.EnableBatchProcessing;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableBatchProcessing
@EnableScheduling
public class BatchScraperApplication {

	public static void main(String[] args) {
		SpringApplication.run(BatchScraperApplication.class, args);
	}

}
