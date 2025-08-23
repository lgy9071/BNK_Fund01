package com.example.fund.ai.api.controller;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.*;

import com.example.fund.ai.api.dto.CompareRequest;
import com.example.fund.ai.api.service.CompareAiApiService;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/compare-ai")
@RequiredArgsConstructor
public class CompareAiApiController {

  private final CompareAiApiService compareAiApiService;

  @PostMapping(value = "/compare", produces = MediaType.APPLICATION_JSON_VALUE)
  public ResponseEntity<String> compare(
      @RequestBody CompareRequest req,
      @AuthenticationPrincipal Jwt jwt
  ) {
    Integer userId = null;
    if (jwt != null) {
      Object claim = jwt.getClaims().get("userId"); // 토큰에 userId 클레임이 있다고 가정
      if (claim != null) {
        try { userId = Integer.valueOf(String.valueOf(claim)); } catch (Exception ignored) {}
      }
    }

    String json = compareAiApiService.compareByUserAndFundIdsReturnJson(userId, req.getFunds());
    return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).body(json);
  }
}
