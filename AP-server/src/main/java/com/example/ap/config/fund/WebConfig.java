package com.example.ap.config.fund;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.example.ap.config.admin.AdminLoginCheckInterceptor;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        // 사용자용 인터셉터
        // registry.addInterceptor(new UserLoginCheckInterceptor())
        // .addPathPatterns("/user/**")
        // .excludePathPatterns("/login","/join", "/css/**", "/js/**");

        // 관리자용 인터셉터
        registry.addInterceptor(new AdminLoginCheckInterceptor())
                .addPathPatterns("/admin/**") // 보호할 URL 지정
                .excludePathPatterns("/admin/", "/admin/login", "/css/**", "/js/**", "/mypage/**"); // 로그인 없이 허용 할 경로
    }
}
