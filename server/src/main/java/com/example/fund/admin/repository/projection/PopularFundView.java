package com.example.fund.admin.repository.projection;

/**
 * 인기 펀드 조회용 Projection
 * - 대시보드 / 통계 화면에서 TOP 펀드 목록 표시 목적
 */
public interface PopularFundView {
    String getFundId();              // 펀드 ID
    String getFundName();            // 펀드명
    String getManagementCompany();   // 운용사
    Long getClicks();                // 클릭 수
    Long getUsers();                 // 유니크 사용자 수
}