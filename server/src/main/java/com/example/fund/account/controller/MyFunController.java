package com.example.fund.account.controller;

import com.example.fund.account.dto.MyFundDto;
import com.example.fund.account.service.MyFundService;
import com.example.fund.common.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/funds")
@RequiredArgsConstructor
public class MyFunController {

    private final MyFundService myFundService;

    /**
     * 사용자 가입 펀드 목록 조회
     * GET /api/funds/my/{userId}
     */
    @GetMapping("/my/{userId}")
    public ResponseEntity<ApiResponse<List<MyFundDto>>> getMyFunds(
            @PathVariable Integer userId
    ) {
        try {
            // 입력 검증
            if (userId == null || userId <= 0) {
                log.warn("유효하지 않은 사용자 ID: {}", userId);
                ApiResponse<List<MyFundDto>> response = ApiResponse.failure(
                        "유효하지 않은 사용자 ID입니다.",
                        "INVALID_USER_ID"
                );
                return ResponseEntity.badRequest().body(response);
            }

            log.info("사용자 {}의 가입 펀드 목록 조회 요청", userId);

            // 서비스 호출
            List<MyFundDto> myFunds = myFundService.getMyFunds(userId);

            // 성공 응답
            ApiResponse<List<MyFundDto>> response = ApiResponse.success(
                    myFunds,
                    "가입 펀드 목록 조회 성공"
            );

            log.info("사용자 {}의 가입 펀드 {}개 조회 완료", userId, myFunds.size());
            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.error("잘못된 요청 파라미터: {}", e.getMessage());
            ApiResponse<List<MyFundDto>> response = ApiResponse.failure(
                    "잘못된 요청입니다.",
                    "INVALID_REQUEST"
            );
            return ResponseEntity.badRequest().body(response);

        } catch (Exception e) {
            log.error("가입 펀드 목록 조회 중 오류 발생", e);
            ApiResponse<List<MyFundDto>> response = ApiResponse.failure(
                    "서버 내부 오류가 발생했습니다.",
                    "INTERNAL_ERROR"
            );
            return ResponseEntity.internalServerError().body(response);
        }
    }

    /**
     * Query Parameter 방식으로도 지원 (선택사항)
     * GET /api/funds/my?userId=1
     */
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<List<MyFundDto>>> getMyFundsWithParam(
            @RequestParam Integer userId
    ) {
        return getMyFunds(userId);  // 위의 메서드 재사용
    }
}
