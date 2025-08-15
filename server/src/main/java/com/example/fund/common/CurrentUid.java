package com.example.fund.common;

import java.lang.annotation.*;

import org.springframework.security.core.annotation.AuthenticationPrincipal;

// @CurrentUid
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@AuthenticationPrincipal(expression = "getClaim('uid')" // ← 여기!
)
public @interface CurrentUid {
}
