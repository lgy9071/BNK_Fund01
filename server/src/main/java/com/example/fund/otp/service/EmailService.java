package com.example.fund.otp.service;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;


@Service
@RequiredArgsConstructor
public class EmailService {
    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    /** OTP 인증번호를 이메일로 발송 */
    public void sendOtpEmail(String toEmail, String otpCode) {
        try {
            SimpleMailMessage message = new SimpleMailMessage();

            // 발송자 (application-secret.properties에서 가져옴)
            message.setFrom(fromEmail);

            // 수신자
            message.setTo(toEmail);

            // 제목
            message.setSubject("인증번호 발송");

            // 내용
            String emailContent = String.format(
                    "안녕하세요!\n\n" +
                            "요청하신 인증번호는 다음과 같습니다:\n\n" +
                            "인증번호: %s\n\n" +
                            "이 인증번호는 3분간 유효합니다.\n" +
                            "타인에게 절대 알려주지 마세요.\n\n" +
                            "감사합니다.",
                    otpCode
            );
            message.setText(emailContent);

            // 이메일 발송
            mailSender.send(message);

            System.out.println("✅ 이메일 발송 성공: " + toEmail);

        } catch (Exception e) {
            System.err.println("❌ 이메일 발송 실패: " + e.getMessage());
            throw new RuntimeException("이메일 발송에 실패했습니다.", e);
        }
    }
}