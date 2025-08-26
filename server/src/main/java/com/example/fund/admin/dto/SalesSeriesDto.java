package com.example.fund.admin.dto;

import com.example.fund.admin.repository.projection.SalesPoint;

public record SalesSeriesDto(java.util.List<String> labels,
                             java.util.List<java.math.BigDecimal> values) {
    public static SalesSeriesDto from(java.util.List<? extends SalesPoint> rows) {
        var labels = rows.stream().map(SalesPoint::getLabel).toList();
        var values = rows.stream().map(SalesPoint::getValue).toList();
        return new SalesSeriesDto(labels, values);
    }
}
