package com.example.fund;


import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@SpringBootApplication
@EnableJpaAuditing
public class BnkProject02Application {

	public static void main(String[] args) {
		SpringApplication.run(BnkProject02Application.class, args);
	}

}
