package com.example.was.controller.fund;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.example.common.entity.fund.User;

import jakarta.servlet.http.HttpSession;

@Controller
public class MainController {

    private static final String SESSION_KEY = "user";

    @GetMapping("/")
    public String main(HttpSession session, Model model) {
        User user = (User) session.getAttribute(SESSION_KEY);

        if (user != null) {
            model.addAttribute("name", user.getName());

            // 세션 남은 시간 계산 (초 단위)
            int maxInactiveInterval = session.getMaxInactiveInterval(); // ex) 600초
            long lastAccessedTime = session.getLastAccessedTime();
            long currentTime = System.currentTimeMillis();
            long remaining = (lastAccessedTime + (maxInactiveInterval * 1000L)) - currentTime;

            if (remaining > 0) {
                model.addAttribute("sessionRemaining", remaining / 1000); // 초로 변환
            }
        }

        return "user/index";
    }
}
