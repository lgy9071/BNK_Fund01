package com.example.fund.fund.controller;

import com.example.fund.fund.entity_fund_etc.InvestProfileResult;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;
import com.example.fund.fund.service.FundService;
import com.example.fund.user.entity.User;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.Optional;

@Slf4j
@Controller
@RequiredArgsConstructor
@RequestMapping("/fund")
public class FundViewController {
    private final InvestProfileResultRepository investProfileResultRepository;
    private final FundService fundService;

    /**
     * 투자 성향에 따른 펀드 목록
     */
    @GetMapping("/list")
    public String listPage(
            HttpSession session,
            Model model
    ) {
        log.debug("펀드 목록 페이지 접근 요청");
        User user = (User) session.getAttribute("user");

        // 사용자 세션 여부
        if (user == null) {
            log.warn("미인증 사용자의 펀드 목록 페이지 접근 시도");
            return "redirect:/auth/login";      // 로그인 필요
        }

        // 투자 성향 존재 여부 확인
        Integer userId = user.getUserId();
        Optional<InvestProfileResult> investResult = investProfileResultRepository.findByUser_UserId(userId);

        if (investResult.isPresent()) {
            InvestProfileResult result = investResult.get();
            Integer investType = result.getType().getTypeId().intValue();

            model.addAttribute("userId", userId);
            model.addAttribute("investType", investType);

            return "fund/fundList";
        } else {
            // 투자 성향 검사 필요
            return "redirect:/profile";
        }
    }




    @GetMapping("/best-return")
    public String bestReturnPage(
            HttpSession session,
            Model model
    ) {
        User user = (User) session.getAttribute("user");

        // 사용자 세션 여부
        if (user == null) {
            return "redirect:/auth/login";      // 로그인 필요
        }

        // 투자 성향 존재 여부 확인
        Integer userId = user.getUserId();
        Optional<InvestProfileResult> investResult = investProfileResultRepository.findByUser_UserId(userId);

        if (investResult.isPresent()) {
            InvestProfileResult result = investResult.get();
            Integer investType = result.getType().getTypeId().intValue();

            model.addAttribute("userId", userId);
            model.addAttribute("investType", investType);

            return "fund/fundThemeList";
        } else {
            // 투자 성향 검사 필요
            return "redirect:/profile";
        }
    }


    @GetMapping("/{fundId}")  // 상세 페이지
    public String detailPage(
            @PathVariable String fundId,
            HttpSession session,
            Model model
    ) {
        // 사용자 세션 여부
        User user = (User) session.getAttribute("user");
        if (user == null) {
            // 로그인 필요
            return "redirect:/auth/login";
        }

        // 투자 성향 존재 여부 확인
        Integer userId = user.getUserId();
        Optional<InvestProfileResult> investResult = investProfileResultRepository.findByUser_UserId(userId);
        if (!investResult.isPresent()) {
            // 투자 성향 검사 필요
            return "redirect:/profile";
        }

        // 펀드 존재 여부 및 접근 권한 확인
        if (!fundService.existsFund(fundId)) {
            log.warn("존재하지 않는 펀드 접근 시도 - userId: {}, fundId: {}", userId, fundId);
            return "redirect:/fund/list";      // 펀드 목록으로 리다이렉트
        }

        InvestProfileResult result = investResult.get();    // 투자 성향 결과
        Integer investType = result.getType().getTypeId().intValue();   // 투자 성향 번호

        model.addAttribute("userId", userId);
        model.addAttribute("investType", investType);
        model.addAttribute("fundId", fundId);

        return "fund/fundDetail";
    }

}
