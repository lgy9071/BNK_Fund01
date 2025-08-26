package com.example.fund.admin.dto;

public record PopularFundDto(
    String id,
    String name,
    String company,
    long clicks,
    long users
) {}