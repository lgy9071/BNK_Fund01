package com.example.fund.otp.templates;

public class OtpMailTemplate {
    public static String text(String otp) {
        return "BNK 인증번호: %s (3분 내 입력)".formatted(otp);
    }
    public static String html(String otp) {
        return """
            <div style="font-family:sans-serif;line-height:1.6">
              <h2>BNK 인증번호</h2>
              <p>인증번호는 <b style="font-size:18px">%s</b> 입니다.</p>
              <p>유효시간은 <b>3분</b>입니다. 타인에게 공유하지 마세요.</p>
            </div>
        """.formatted(otp);
    }
}
