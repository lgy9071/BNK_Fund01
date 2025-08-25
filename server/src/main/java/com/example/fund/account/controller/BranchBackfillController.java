// src/main/java/com/example/fund/account/controller/BranchBackfillController.java
package com.example.fund.account.controller;

import com.example.fund.account.service.BranchBackfillService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/branches")
public class BranchBackfillController {

    private final BranchBackfillService backfillService;

    /**
     * 좌표 백필 트리거
     * 예) DRYRUN(저장 안 함): POST /api/branches/backfill?dryRun=true&limit=100
     * 예) 저장: POST /api/branches/backfill?dryRun=false&limit=0
     */
    @PostMapping("/backfill")
    public Map<String,Object> backfill(@RequestParam(defaultValue="false") boolean dryRun,
                                       @RequestParam(defaultValue="0") int limit,
                                       @RequestParam(defaultValue="200") int pageSize) {
      int updated = backfillService.backfillLatLng(limit, pageSize, dryRun);
      return Map.of("dryRun", dryRun, "updated", updated);
    }
}
