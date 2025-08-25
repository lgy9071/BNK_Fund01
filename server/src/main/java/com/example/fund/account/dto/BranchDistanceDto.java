package com.example.fund.account.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class BranchDistanceDto {
    private Long   branchId;
    private String branchName;
    private String address;
    private double distanceMeters; // 내 위치와의 직선거리(m)
    private Double lat;            // 지점 위도(지오코딩 결과)
    private Double lng;            // 지점 경도(지오코딩 결과)
}
