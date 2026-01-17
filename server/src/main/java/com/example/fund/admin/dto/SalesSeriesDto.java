package com.example.fund.admin.dto;

import com.example.fund.admin.repository.projection.SalesPoint;

public record SalesSeriesDto(
        // 차트의 X축에 사용될 라벨 목록 (예: 날짜, 월, 상품명 등)
        java.util.List<String> labels,

        // 차트의 Y축에 사용될 값 목록 (매출 금액 등)
        java.util.List<java.math.BigDecimal> values
) {

    /**
     * SalesPoint 리스트를 받아
     * 차트에 바로 사용 가능한 SalesSeriesDto로 변환하는 정적 팩토리 메서드
     *
     * @param rows SalesPoint 구현체 리스트
     * @return labels와 values가 분리된 SalesSeriesDto 객체
     */
    public static SalesSeriesDto from(java.util.List<? extends SalesPoint> rows) {

        // SalesPoint의 label 값을 추출하여 labels 리스트 생성
        var labels = rows.stream()
                .map(SalesPoint::getLabel)
                .toList();

        // SalesPoint의 value 값을 추출하여 values 리스트 생성
        var values = rows.stream()
                .map(SalesPoint::getValue)
                .toList();

        // 변환된 데이터로 SalesSeriesDto 생성 후 반환
        return new SalesSeriesDto(labels, values);
    }
}
