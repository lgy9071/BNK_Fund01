package com.example.fund.clickLog.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.clickLog.service.FundClickLogService;
import com.example.fund.common.CurrentUid;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/funds")
@RequiredArgsConstructor
public class FundClickController {

    private final FundClickLogService clickService;

    @PostMapping("/{fundId}/click")
    public ResponseEntity<Void> logClick(@PathVariable Long fundId,
                                         @CurrentUid Long uid) {
        if (uid == null) return ResponseEntity.status(401).build();
        clickService.logClick(fundId, uid);
        return ResponseEntity.status(201).build();
    }
}
