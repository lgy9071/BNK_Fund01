package com.example.fund.otp.service;

import com.example.fund.otp.entity.OtpCode;
import com.example.fund.otp.repository.OtpCodeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Retryable;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class OtpService {

    private final OtpCodeRepository otpRepository;
    private final EmailService emailService;
    private final SecureRandom random = new SecureRandom();

    private String generateCode() {
        int n = random.nextInt(1_000_000);
        return String.format("%06d", n);
    }

    @Retryable(
            // value = {DataAccessException.class},
            // maxAttempts = 3,
            backoff = @Backoff(delay = 100, multiplier = 2)
    )
    @Transactional(
            isolation = Isolation.SERIALIZABLE,  // ✅ 해결: 최고 격리 수준
            timeout = 30,
            rollbackFor = Exception.class
    )
    public void requestOtp(String email) {
        log.info("OTP 요청 시작: {}", email);

        String code = generateCode(); // 🔥 한 번만 생성하고 저장

        try {
            // DB 작업
            otpRepository.invalidateExistingOtps(email);
            otpRepository.flush();

            OtpCode otpCode = new OtpCode();
            otpCode.setEmail(email);
            otpCode.setCode(code);
            otpRepository.save(otpCode);

            log.info("OTP DB 저장 완료: {} (코드: {})", email, code);

        } catch (Exception e) {
            log.error("OTP DB 저장 실패: {}", email, e);
            throw e;
        }

        sendEmailAsync(email, code);
    }

    /**
     * 이메일 발송을 별도 트랜잭션으로 분리
     */
    @Async  // 또는 별도 트랜잭션
    public void sendEmailAsync(String email, String code) {
        try {
            emailService.sendOtpEmail(email, code);
            log.info("📧 OTP 이메일 발송 완료: {}", email);
        } catch (Exception e) {
            log.error("📧 OTP 이메일 발송 실패: {}", email, e);
            // DB 롤백하지 않음 - 이메일은 재발송 가능
        }
    }


    /**
     * 🔥 문제 해결 2: 비관적 락으로 Race Condition 해결
     */
    @Retryable(
            // value = {DataAccessException.class},
            // maxAttempts = 2,
            backoff = @Backoff(delay = 50)
    )
    @Transactional(
            isolation = Isolation.SERIALIZABLE,  // ✅ 해결: 엄격한 격리
            timeout = 15,
            rollbackFor = Exception.class
    )
    public boolean verifyOtp(String email, String inputOtp) {
        log.info("OTP 검증 시작: {}", email);

        try {
            // ✅ 해결: 비관적 락으로 동시 접근 차단
            var otpOpt = otpRepository.findValidOtpByEmailWithLock(
                    email, LocalDateTime.now()
            );

            if (otpOpt.isEmpty()) {
                log.warn("유효한 OTP 없음: {}", email);
                return false;
            }

            OtpCode otp = otpOpt.get();
            log.debug("OTP 조회 완료 (락 보유): {} (시도: {}/5)", email, otp.getAttempts());

            // 이제 락으로 보호되므로 안전한 검증 가능
            if (otp.getAttempts() >= 5) {
                otp.setUsed(true);
                otpRepository.save(otp);
                log.warn("최대 시도 횟수 초과: {}", email);
                return false;
            }

            if (otp.getCode().equals(inputOtp)) {
                otp.setUsed(true);
                otpRepository.save(otp);
                log.info("OTP 인증 성공: {}", email);
                return true;
            } else {
                otp.setAttempts(otp.getAttempts() + 1);
                otpRepository.save(otp);
                log.warn("OTP 불일치: {} (시도: {}/5)", email, otp.getAttempts());
                return false;
            }

        } catch (Exception e) {
            log.error("OTP 검증 실패: {}", email, e);
            throw e;
        }
    }
}






/*


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
*/


/*
@Service
@RequiredArgsConstructor
@Transactional
public class OtpService {

    // 🔥 변경: OtpStore 대신 Repository 사용
    private final OtpCodeRepository otpRepository;
    private final EmailService emailService;
    private final SecureRandom random = new SecureRandom();

    @PersistenceContext
    private EntityManager entityManager;

    // 6자리 숫자 생성
    private String generateCode() {
        int n = random.nextInt(1_000_000); // 000000 ~ 999999
        return String.format("%06d", n);
    }

    public void requestOtp(String email) {
        String code = generateCode();

        // 🔥 변경: 기존 미사용 OTP 무효화
        otpRepository.invalidateExistingOtps(email);

        // 🔥 변경: DB에 새 OTP 저장
        OtpCode otpCode = new OtpCode();
        otpCode.setEmail(email);
        otpCode.setCode(code);
        otpRepository.save(otpCode);

        // 이메일 발송
        try {
            emailService.sendOtpEmail(email, code);
            System.out.println("📧 OTP 이메일 발송 완료: " + email);
            System.out.println("💾 OTP DB 저장 완료: " + code + " (만료: 3분)");
        } catch (Exception e) {
            System.err.println("📧 OTP 이메일 발송 실패: " + e.getMessage());
            throw new RuntimeException("이메일 발송에 실패했습니다.", e);
        }
    }

    public boolean verifyOtp(String email, String inputOtp) {
        // 🔥 변경: DB에서 유효한 OTP 조회
        var otpOpt = otpRepository.findValidOtpByEmail(email, LocalDateTime.now());

        if (otpOpt.isEmpty()) {
            System.out.println("❌ OTP 없음 또는 만료됨: " + email);
            return false;
        }

        OtpCode otp = otpOpt.get();

        // 최대 시도 횟수 체크 (5회)
        if (otp.getAttempts() >= 5) {
            otp.setUsed(true); // 무효화
            otpRepository.save(otp);
            System.out.println("❌ 최대 시도 횟수 초과: " + email);
            return false;
        }

        // 코드 검증
        if (otp.getCode().equals(inputOtp)) {
            otp.setUsed(true); // 사용 완료 표시
            otpRepository.save(otp);
            System.out.println("✅ OTP 인증 성공: " + email);
            return true;
        } else {
            otp.setAttempts(otp.getAttempts() + 1);
            otpRepository.save(otp);
            System.out.println("❌ OTP 불일치: " + email + " (시도: " + otp.getAttempts() + "/5)");
            return false;
        }
    }
}

*/