package com.example.fund.fund.dto;

// record : Java 16+부터 생긴 불변(immutable) 데이터 전용 타입.
// equals/hashCode/toString을 자동으로 생성
public record FundProductDocDto(Long id, String type, String fileName, String path) {}