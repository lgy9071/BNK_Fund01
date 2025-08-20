package com.example.fund.account.service;

import com.example.fund.account.store.OtpStore;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;

@Service
public class OtpService {
    private final OtpStore store = new OtpStore();
    private final SecureRandom random = new SecureRandom();

    // 6자리 숫자 생성
    private String generateCode() {
        int n = random.nextInt(1_000_000); // 000000 ~ 999999
        return String.format("%06d", n);
    }

    public void requestOtp(String email) {
        String code = generateCode();
        store.put(email, code);

        // 실제에선 이메일 발송(API/SMTP). 여기선 콘솔로 대체
        System.out.println("[MAIL] To: " + email + " / OTP: " + code + " / 3분 내 입력");
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