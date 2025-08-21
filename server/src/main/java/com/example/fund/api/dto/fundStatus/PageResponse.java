package com.example.fund.api.dto.fundStatus;

public record PageResponse<T>(
        java.util.List<T> content, int page, int size, long totalElements, boolean last) {
}