package com.example.ap;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EntityScan("com.example.common.entity")
@EnableJpaRepositories("com.example.ap.repository")
public class ApApplication {

	public static void main(String[] args) {
		SpringApplication.run(ApApplication.class, args);
	}

}
