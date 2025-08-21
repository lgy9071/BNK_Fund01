package com.example.fund.otp.service;

import com.example.fund.otp.store.OtpStore;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;


@Service
@RequiredArgsConstructor  // EmailService 주입을 위해 추가
public class OtpService {
    private final OtpStore store = new OtpStore();
    private final SecureRandom random = new SecureRandom();
    private final EmailService emailService;  // 이메일 서비스 주입

    // 6자리 숫자 생성
    private String generateCode() {
        int n = random.nextInt(1_000_000); // 000000 ~ 999999
        return String.format("%06d", n);
    }

    public void requestOtp(String email) {
        String code = generateCode();
        store.put(email, code);

        // 🔥 변경된 부분: 콘솔 대신 실제 이메일 발송
        try {
            emailService.sendOtpEmail(email, code);
            System.out.println("📧 OTP 이메일 발송 완료: " + email);
        } catch (Exception e) {
            System.err.println("📧 OTP 이메일 발송 실패: " + e.getMessage());
            // 실제 운영에서는 사용자에게 오류 메시지를 전달해야 함
        }
    }

    public boolean verifyOtp(String email, String otp) {
        var entry = store.get(email);
        if (entry == null) return false;

        // (선택) 최대 시도횟수 제한(예: 5회)
        if (entry.attempts() >= 5) {
            store.remove(email);
            return false;
        }

        if (entry.code().equals(otp)) {
            store.remove(email); // 일회성 → 즉시 폐기(재사용 방지)
            return true;
        } else {
            store.incrementAttempts(email);
            return false;
        }
    }
}