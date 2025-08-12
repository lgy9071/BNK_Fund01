package com.example.was.controller.fund;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.example.common.entity.fund.User;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
@RequestMapping("/mypage/favorites")
public class FavoriteController {

    private final FundFavoriteService favoriteService;

    /* 관심 펀드 목록 */
    @GetMapping
    public String list(HttpSession session, Model model) {
        User loginUser = (User) session.getAttribute("user");
        model.addAttribute("funds",
                favoriteService.list(loginUser.getUserId()));
        return "mypage/favorite-list";
    }

    /* ♥ 토글 AJAX */
    @PostMapping("/{fundId}/toggle")
    @ResponseBody
    public String toggle(@PathVariable int fundId, HttpSession session) {
        User loginUser = (User) session.getAttribute("user");
        favoriteService.toggle(loginUser.getUserId(), fundId);
        return "ok";
    }
}
