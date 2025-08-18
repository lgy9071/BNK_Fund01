package com.example.fund.common.config;

import java.util.List;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import com.example.fund.admin.config.AdminLoginCheckInterceptor;
import com.example.fund.common.CurrentUidArgumentResolver;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final CurrentUidArgumentResolver resolver;

    public WebConfig(CurrentUidArgumentResolver resolver) {
        this.resolver = resolver;
    }

    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(resolver);
    }

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
