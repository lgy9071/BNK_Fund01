package com.example.fund.account.dto;

public record JoinCheckResponse(
	    boolean hasDepositAccount,
	    boolean hasValidInvestProfile,
	    String nextAction // "OPEN_DEPOSIT" | "DO_PROFILE" | "OK"
	) {}