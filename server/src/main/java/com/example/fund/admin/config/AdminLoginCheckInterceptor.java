package com.example.fund.admin.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.web.servlet.HandlerInterceptor;

public class AdminLoginCheckInterceptor implements HandlerInterceptor {

    /**
     * 컨트롤러가 실행되기 전에 호출되는 메서드
     * true 를 반환하면 요청을 계속 진행하고,
     * false 를 반환하면 요청을 중단한다.
     */
    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {

        // 기존 세션이 존재하면 가져오고, 없으면 새로 생성하지 않고 null 반환
        HttpSession session = request.getSession(false); // false: session이 없을 시 null 반환

        // 현재 세션 ID 출력 (세션이 없으면 "없음" 출력)
        System.out.println("세션 ID: " + (session != null ? session.getId() : "없음"));

        // 세션이 없거나, 세션에 "admin" 속성이 없으면 (로그인하지 않은 상태)
        if (session == null || session.getAttribute("admin") == null) {

            // 인터셉터에서 차단된 요청 URI 출력
            System.out.println("인터셉터 감지 URI: " + request.getRequestURI());

            // 관리자 로그인 페이지로 리다이렉트하며 에러 파라미터 전달
            response.sendRedirect("/admin/?error=needLogin"); // 로그인 정보가 없을 시 login 화면으로 이동

            // 요청을 더 이상 진행하지 않음 (컨트롤러 진입 차단)
            return false;
        }

        // 로그인 상태이면 요청을 정상적으로 컨트롤러까지 진행
        return true;
    }

}
