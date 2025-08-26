package com.example.fund.admin.repository.projection;

public interface PopularFundView {
    String getFundId();
    String getFundName();
    String getManagementCompany();
    Long getClicks();
    Long getUsers();
}
