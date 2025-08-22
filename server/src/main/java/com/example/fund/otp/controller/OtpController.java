package com.example.fund.otp.controller;

import com.example.fund.otp.dto.OptResponse;
import com.example.fund.otp.dto.OtpRequest;
import com.example.fund.otp.dto.OtpVerifyRequest;
import com.example.fund.otp.service.OtpService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;


@CrossOrigin(origins = "*")
@RestController
@RequiredArgsConstructor
@RequestMapping("/otp")
public class OtpController {
    private final OtpService otpService;

    private final Map<String, LocalDateTime> recentRequests = new ConcurrentHashMap<>();

    @PostMapping("/request")
    public ResponseEntity<OptResponse> request(
            @RequestBody @Valid OtpRequest req
    ) {
        String email = req.getEmail();

        // 1분 내 동일 이메일 요청 차단
        LocalDateTime lastRequest = recentRequests.get(email);
        if (lastRequest != null && lastRequest.isAfter(LocalDateTime.now().minusMinutes(1))) {
            return ResponseEntity.ok(new OptResponse(true, "이미 발송된 인증번호를 확인해주세요."));
        }

        // OTP 요청 처리
        otpService.requestOtp(email);

        // 요청 시간 기록
        recentRequests.put(email, LocalDateTime.now());

        return ResponseEntity.ok(new OptResponse(true, "인증번호를 전송했습니다."));

    }


    @PostMapping("/verify")
    public ResponseEntity<OptResponse> verify(
            @RequestBody @Valid OtpVerifyRequest req
    ) {
        boolean ok = otpService.verifyOtp(req.getEmail(), req.getOtp());
        if (ok) return ResponseEntity.ok(new OptResponse(true, "신원 확인 완료"));
        return ResponseEntity.status(401).body(new OptResponse(false, "인증번호가 올바르지 않거나 만료되었습니다."));
    }
}



/*

// 간단 검증: 이메일 형식만 체크(실제론 가입된 이메일인지도 확인)
if (req.getEmail() == null || !req.getEmail().contains("@")) {
    return ResponseEntity.badRequest().body(
            new OptResponse(false, "이메일 형식이 잘못되었습니다.")
    );
}
otpService.requestOtp(req.getEmail());
return ResponseEntity.ok(new OptResponse(true, "인증번호를 전송했습니다. 3분 내 입력하세요."));

*/