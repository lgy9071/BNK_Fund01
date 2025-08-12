package com.example.was.controller.fund;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.ap.service.fund.QnaService;
import com.example.ap.service.fund.UserService;
import com.example.common.dto.fund.UserUpdateRequest;
import com.example.common.entity.fund.User;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
@RequestMapping("/mypage")
public class MypageController {

    private final UserService service;
    private final QnaService qnaService;
    private static final String SESSION_KEY = "user";

    /* ────────────────── 1. 마이페이지 홈 : 탭만 표시 ────────────────── */
    @GetMapping
    public String home(HttpSession session, Model model) {
        User user = (User) session.getAttribute("user");
        if (user == null)
            return "redirect:/auth/login";
        String investType = service.user_invertType(user.getUserId());
        long countQna = service.countUserQna(user.getUserId());
        model.addAttribute("investType", investType);
        model.addAttribute("user", user);
        model.addAttribute("countQna", countQna);

        return "mypage/index"; // 내용 없는 화면
    }

    /* ────────────────── 2. 정보수정 폼 ────────────────── */
    @GetMapping("/edit")
    public String editForm(HttpServletRequest request,
            HttpSession session,
            Model m) {

        User user = (User) session.getAttribute(SESSION_KEY);
        if (user == null)
            return "redirect:/auth/login";

        m.addAttribute("updateRequest",
                UserUpdateRequest.builder()
                        .username(user.getUsername())
                        .name(user.getName())
                        .phone(user.getPhone())
                        .build());

        m.addAttribute("requestURI", request.getRequestURI());
        return "mypage/form";
    }

    /* ────────────────── 3. 정보수정 처리 ────────────────── */
    @PostMapping("/edit")
    public String update(@Valid @ModelAttribute("updateRequest") UserUpdateRequest dto,
            BindingResult br,
            HttpServletRequest request,
            HttpSession session,
            Model m, RedirectAttributes rttr) {

        User user = (User) session.getAttribute(SESSION_KEY);
        if (user == null)
            return "redirect:/auth/login";

        if (dto.isChangingPassword() && !dto.newPwMatches()) {
            br.rejectValue("confirmNewPassword", "nomatch", "새 비밀번호가 서로 다릅니다.");
        }
        if (br.hasErrors()) {
            rttr.addFlashAttribute("requestURI", request.getRequestURI());
            return "mypage/form";
        }

        try {
            User updated = service.updateProfile(user.getUserId(), dto);
            session.setAttribute(SESSION_KEY, updated);
            rttr.addFlashAttribute("success", "변경되었습니다.");
        } catch (IllegalStateException e) {
            rttr.addFlashAttribute("updateError", e.getMessage());
            return "redirect:/mypage/edit";
        }

        return "redirect:/mypage";
    }

    /* ────────────────── 4. 내 1:1 문의 목록 ────────────────── */
    @GetMapping("/qna")
    public String myQnaList(HttpServletRequest request,
            HttpSession session,
            Model m) {

        User user = (User) session.getAttribute(SESSION_KEY);
        if (user == null)
            return "redirect:/auth/login";

        long countQna = service.countUserQna(user.getUserId());
        m.addAttribute("countQna", countQna);
        m.addAttribute("qnaList", qnaService.getQnaListByUser(user.getUserId()));
        return "mypage/qna-list";
    }

}
