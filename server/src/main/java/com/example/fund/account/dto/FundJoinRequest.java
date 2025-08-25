package com.example.fund.account.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class FundJoinRequest {
    private String fundId;
    private Long amount;       // 원 단위
    private String rawPin;     // 4자리
    private String branchName; // 선택 시 지점명, 없으면 null
    private String ruleType;   // "ONE_TIME" | "DAILY" | "WEEKLY" | "MONTHLY"
    private String ruleValue;  // "", "FRI", "DAY_15" 등
}
