package com.example.fund.admin.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.admin.service.StatsService;
import com.example.fund.admin.service.StatsService.ProfileDto;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/admin/api/stats")
@RequiredArgsConstructor
public class StatsController {

    private final StatsService statsService;

    // GET /admin/api/stats/investor-profiles
    @GetMapping("/investor-profiles")
    public List<ProfileDto> investorProfiles() {
        return statsService.getInvestorProfiles();
    }
}