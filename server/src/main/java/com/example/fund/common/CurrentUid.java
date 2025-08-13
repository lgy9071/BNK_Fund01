package com.example.fund.common;

import java.lang.annotation.*;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

@Target(ElementType.PARAMETER) // 메서드 파라미터에서만 사용
@Retention(RetentionPolicy.RUNTIME)
@Documented
@AuthenticationPrincipal(expression = "claims['uid']") // 토큰에서 uid 클레임 추출
public @interface CurrentUid {
    
}
