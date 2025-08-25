package com.example.fund.account.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public record AgreementConfirmRequest(
	@JsonProperty("productId")
    Long productId,
    boolean termsAgreed,      // 약관동의 체크박스
    boolean docConfirmed      // 비예금상품설명서 "확인했습니다" 버튼
) {}