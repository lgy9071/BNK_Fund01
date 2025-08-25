package com.example.fund.account.geocode;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "naver.geocode")
public record GeocodeProps(
        String baseUrl,
        String apiKeyId,
        String apiKey,
        Integer timeoutMs,
        Integer minIntervalMs
) {}
