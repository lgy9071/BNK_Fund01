package com.example.ap.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class CorsConfig {
  @Bean
  public WebMvcConfigurer corsConfigurer() {
    return new WebMvcConfigurer() {
      @Override
      public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
          .allowedOrigins("http://localhost:8090") // WAS(브라우저가 열어주는 페이지)
          .allowedMethods("GET","POST","PUT","DELETE","PATCH","OPTIONS")
          .allowedHeaders("*")                     // Authorization, Content-Type 등
          .exposedHeaders("Location")              // 필요시
          .allowCredentials(true)
          .maxAge(3600);
      }
    };
  }
}