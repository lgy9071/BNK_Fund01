// src/main/java/.../HolidayApiProps.java
package com.example.fund.holiday;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "holiday.api")
public record HolidayApiProps(String baseUrl, String serviceKey, int timeoutMs) {}
