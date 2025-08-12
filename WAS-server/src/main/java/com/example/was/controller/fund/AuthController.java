package com.example.was.controller.fund;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.common.dto.fund.JoinRequest;
import com.example.common.dto.fund.LoginRequest;
import com.example.common.entity.fund.User;
import com.example.fund.auth.service.UserService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
@RequestMapping("/auth")
public class AuthController {

    private final UserService service;
    private static final String SESSION_KEY = "user";

    /**
     *  회원가입 폼 제공
     */
    @GetMapping("/join")
    public String joinForm(Model m) {
        m.addAttribute("joinRequest", new JoinRequest());
        return "auth/join";
    }

    /**
     *  회원가입 처리 메서드
     */
    @PostMapping("/join")
    public String join(
            @Valid @ModelAttribute JoinRequest dto,
            BindingResult br,
            Model m
    ) {
        if (!dto.samePassword())
            br.rejectValue("confirmPassword", "nomatch", "비밀번호가 일치하지 않습니다.");
        if (br.hasErrors())
            return "auth/join";

        try {
            service.register(dto);
        } catch (IllegalStateException e) {
            m.addAttribute("joinError", e.getMessage());
            return "auth/join";
        }
        return "redirect:/auth/login";
    }

    /* ===== 로그인 ===== */
    @GetMapping("/login")
    public String loginForm(Model m) {
        m.addAttribute("loginRequest", new LoginRequest());
        return "auth/login";
    }

    @PostMapping("/login")
    public String login(
            @Valid @ModelAttribute LoginRequest dto,
            BindingResult br,
            HttpSession session,
            Model m
    ) {
        if (br.hasErrors())
            return "auth/login";

        User user = service.login(dto.getUsername(), dto.getPassword());
        if (user == null) {
            m.addAttribute("loginError", "아이디 또는 비밀번호가 틀렸습니다.");
            return "auth/login";
        }
        session.setAttribute(SESSION_KEY, user); // 세션에 등록
        return "redirect:/";
    }

    /* ===== 로그아웃 ===== */
    @GetMapping("/logout")
    public String logout(RedirectAttributes rttr, HttpServletRequest request) {
        request.getSession().removeAttribute("user");
        rttr.addFlashAttribute("logoutMsg", "로그아웃"); // 세션 제거
        return "redirect:/";
    }
}
