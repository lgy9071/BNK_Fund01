package com.example.fund.account.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.account.dto.BranchDistanceDto;
import com.example.fund.account.service.NearbyBranchService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api")
public class NearbyBranchController {

    private final NearbyBranchService nearbyBranchService;

    /**
     * 예: GET /api/branches/nearby?lat=35.1796&lng=129.0756
     * radiusMeters 생략 시 3000m(3km) 기본값
     */
    @GetMapping("/branches/nearby")
    public List<BranchDistanceDto> nearby(@RequestParam("lat") double myLat,
                                          @RequestParam("lng") double myLng,
                                          @RequestParam(name = "radiusMeters", defaultValue = "3000")
                                          double radiusMeters) {
        log.info("📌 Nearby API 호출 lat={}, lng={}, radius={}", myLat, myLng, radiusMeters);

        List<BranchDistanceDto> result = nearbyBranchService.findWithinRadius(myLat, myLng, radiusMeters);

        log.info("📌 Nearby API 결과 건수={}", result.size());
        return result;
    }

}
