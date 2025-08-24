package com.example.fund.otp.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import com.example.fund.otp.templates.OtpMailTemplate;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;


@Service
@RequiredArgsConstructor
public class EmailService {
    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromEmail;

    /** OTP 인증번호를 이메일로 발송 */
    public void sendOtpEmail(String toEmail, String otpCode) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(fromEmail);
            helper.setTo(toEmail);
            helper.setSubject("인증번호 발송");

            // HTML 템플릿 사용
            String htmlContent = OtpMailTemplate.html(otpCode);
            helper.setText(htmlContent, true); // true = HTML 형식

            mailSender.send(message);
            System.out.println("✅ HTML 이메일 발송 성공: " + toEmail);
        } catch (Exception e) {
            System.err.println("❌ 이메일 발송 실패: " + e.getMessage());
            throw new RuntimeException("이메일 발송에 실패했습니다.", e);
        }
    }
}

/*


public void sendOtpEmail(String toEmail, String otpCode) {
    try {
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(fromEmail); // 발송자
        message.setTo(toEmail);     // 수신자
        message.setSubject("인증번호 발송");      // 제목
        String emailContent = OtpMailTemplate.text(otpCode);    // 내용
        message.setText(emailContent);

        mailSender.send(message);   // 이메일 발송
        System.out.println("✅ 이메일 발송 성공: " + toEmail);
    } catch (Exception e) {
        System.err.println("❌ 이메일 발송 실패: " + e.getMessage());
        throw new RuntimeException("이메일 발송에 실패했습니다.", e);
    }
}


*/