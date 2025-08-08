package com.example.fund.api.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class FundController {

    @GetMapping("/funds")
    public List<Map<String,Object>> listFunds() {
        // 임시 더미 데이터
        Map<String,Object> f1 = Map.of(
                "id", 1,
                "name", "글로벌배분펀드",
                "rate", 3.2,
                "balance", 8_500_000
        );
        Map<String,Object> f2 = Map.of(
                "id", 2,
                "name", "테크성장펀드",
                "rate", -1.1,
                "balance", 4_000_000
        );
        return List.of(f1, f2);
    }
}