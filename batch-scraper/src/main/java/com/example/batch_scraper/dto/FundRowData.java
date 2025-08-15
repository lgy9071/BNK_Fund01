package com.example.batch_scraper.dto;

import java.io.Serializable;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FundRowData implements Serializable {
	// 직렬화 땜에 필요함
    private static final long serialVersionUID = 1L;
    
    // 기본 정보
    private String standardCode;    // 펀드 고유번호
    private String fundName;        // fundNm
    private String riskRate;        // riskRate

    // 수익률
    private String ret1M;           // ropGb1
    private String ret3M;           // ropGb2
    private String ret6M;           // ropGb3
    private String ret12M;          // ropGb5
}

// private String company;         // koreanShotNm