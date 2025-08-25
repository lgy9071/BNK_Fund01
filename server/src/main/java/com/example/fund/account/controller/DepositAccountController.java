package com.example.fund.account.controller;

import com.example.fund.account.dto.CreateDepositAccountRequestDto;
import com.example.fund.account.dto.CreateDepositAccountResponseDto;
import com.example.fund.account.dto.DepositAccountResponseDto;
import com.example.fund.account.service.DepositAccountService;
import com.example.fund.common.dto.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/deposit")
@RequiredArgsConstructor
@Slf4j
@Validated
public class DepositAccountController {

    private final DepositAccountService depositAccountService;

    /**
     * 입출금 계좌 생성
     */
    @PostMapping("/create")
    public ResponseEntity<ApiResponse<CreateDepositAccountResponseDto>> createDepositAccount(
            @Valid @RequestBody CreateDepositAccountRequestDto requestDto
    ) {

        log.info("입출금 계좌 생성 요청 - 사용자ID: {}", requestDto.getUserId());

        try {
            CreateDepositAccountResponseDto responseDto = depositAccountService.createDepositAccount(requestDto);
            return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(responseDto, "입출금 계좌가 성공적으로 생성되었습니다."));
        } catch (IllegalArgumentException e) {
            log.warn("계좌 생성 실패 - 잘못된 요청: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(ApiResponse.failure(e.getMessage(), "INVALID_REQUEST"));
        } catch (Exception e) {
            log.error("계좌 생성 중 예상치 못한 오류 발생", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(ApiResponse.failure("계좌 생성 중 오류가 발생했습니다.", "INTERNAL_ERROR"));
        }
    }

    /**
     * 사용자별 입출금 계좌 목록 조회
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<DepositAccountResponseDto>>> getDepositAccountsByUser(
            @RequestParam @NotNull Integer userId
    ) {

        log.info("사용자 계좌 목록 조회 요청 - 사용자ID: {}", userId);

        try {
            List<DepositAccountResponseDto> accounts =
                    depositAccountService.getAccountsByUserId(userId);

            return ResponseEntity.ok(
                    ApiResponse.success(accounts, "계좌 목록을 성공적으로 조회했습니다.")
            );

        } catch (Exception e) {
            log.error("계좌 목록 조회 중 오류 발생", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure("계좌 목록 조회 중 오류가 발생했습니다.", "INTERNAL_ERROR"));
        }
    }

    /**
     * 계좌번호로 입출금 계좌 조회
     */
    @GetMapping("/{accountNumber}")
    public ResponseEntity<ApiResponse<DepositAccountResponseDto>> getDepositAccountByNumber(
            @PathVariable @NotBlank String accountNumber
    ) {
        log.info("계좌 조회 요청 - 계좌번호: {}", accountNumber);

        try {
            DepositAccountResponseDto account =
                    depositAccountService.getAccountByAccountNumber(accountNumber);

            return ResponseEntity.ok(
                    ApiResponse.success(account, "계좌 정보를 성공적으로 조회했습니다.")
            );

        } catch (IllegalArgumentException e) {
            log.warn("계좌 조회 실패 - 존재하지 않는 계좌: {}", accountNumber);
            return ResponseEntity.status(HttpStatus.NOT_FOUND)
                    .body(ApiResponse.failure(e.getMessage(), "ACCOUNT_NOT_FOUND"));

        } catch (Exception e) {
            log.error("계좌 조회 중 오류 발생", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure("계좌 조회 중 오류가 발생했습니다.", "INTERNAL_ERROR"));
        }
    }

}