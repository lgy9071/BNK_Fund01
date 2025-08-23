package com.example.fund.cdd.controller;


import com.example.fund.cdd.dto.CddRequestDto;
import com.example.fund.cdd.dto.CddResponseDto;
import com.example.fund.cdd.service.CddService;
import com.example.fund.common.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/cdd")
@RequiredArgsConstructor
@Slf4j
public class CddController {
    private final CddService cddService;

    /**
     * CDD 실시 API
     */
    @PostMapping("/process")
    public ResponseEntity<ApiResponse<CddResponseDto>> processCdd(
            @Valid @RequestBody CddRequestDto request
    ) {
        log.info("CDD 처리 요청 수신 - 사용자 ID: {}", request.getUserId());

        try {
            CddResponseDto response = cddService.processCdd(request);
            return ResponseEntity.ok(ApiResponse.success(response, "CDD 요청이 성공적으로 처리되었습니다."));
        } catch (IllegalStateException e) {
            log.warn("CDD 처리 실패: {}", e.getMessage());
            return ResponseEntity.badRequest().body(ApiResponse.failure(e.getMessage(), "CDD_ALREADY_COMPLETED"));
        } catch (Exception e) {
            log.error("CDD 처리 중 오류 발생", e);
            return ResponseEntity.internalServerError().body(ApiResponse.failure("고객확인의무 처리 중 오류가 발생했습니다.", "CDD_PROCESS_ERROR"));
        }
    }
}




/*
백엔드 API 엔드포인트: /cdd/request
HTTP 메소드: POST
Content-Type: application/json

요청 매개변수:
{
  "residentRegistrationNumber": "string", // 주민등록번호 (예: "901225-1234567")
  "address": "string", // 주소
  "nationality": "string", // 국적 ("국내" 또는 "국외")
  "occupation": "string", // 직업
  "incomeSource": "string", // 소득원 ("급여", "사업소득", "투자수익", "연금", "기타" 중 하나)
  "transactionPurpose": "string", // 거래목적 ("투자/재테크", "생활비 관리", "저축/적금", "연금 준비", "자녀 교육비", "기타" 중 하나)
  "requestTimestamp": "string" // 요청 시간 (ISO 8601 형식)
}

응답 예시
- 성공
{
  "success": true,
  "data": {
    "cddId": "123",
    "riskLevel": "LOW",
    "processedAt": "2025-08-22T14:30:00"
  },
  "message": "CDD 요청이 성공적으로 처리되었습니다.",
  "errorCode": null,
  "pagination": null
}

- 실패
{
  "success": false,
  "data": null,
  "message": "이미 고객확인의무가 완료된 사용자입니다.",
  "errorCode": "CDD_ALREADY_COMPLETED",
  "pagination": null
}




















응답 예시:
{
  "success": true,
  "message": "CDD 요청이 성공적으로 처리되었습니다.",
  "cddId": "string", // CDD 처리 ID
  "riskLevel": "string", // 위험등급 (예: "LOW", "MEDIUM", "HIGH")
  "processedAt": "string" // 처리 시간
}

에러 응답 예시:
{
  "success": false,
  "message": "유효하지 않은 주민등록번호입니다.",
  "errorCode": "INVALID_RRN"
}
*/