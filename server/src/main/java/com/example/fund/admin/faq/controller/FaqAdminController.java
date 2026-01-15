package com.example.fund.admin.faq.controller;

import com.example.fund.admin.dto.AdminDTO;
import com.example.fund.admin.faq.service.FaqAdminService;
import com.example.fund.faq.entity.Faq;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/faq") // 관리자 FAQ 관련 URL 공통 경로
public class FaqAdminController {

    private final FaqAdminService faqAdminService;

    /**
     * FAQ 목록 페이지
     * - 키워드 검색
     * - 페이징 처리
     * - 성공/에러 메시지 처리
     */
    @GetMapping("/list")
    public String faqList(@RequestParam(value = "keyword", required = false) String keyword,
                          @RequestParam(defaultValue = "0") int page,
                          Model model, HttpSession session,
                          @ModelAttribute("successMessage") String successMessage,
                          @ModelAttribute("errorMessage") String errorMessage) {

        // 세션에 저장된 관리자 정보 조회
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        model.addAttribute("admin", admin);

        // 페이지당 10개, faqId 내림차순 정렬
        Pageable pageable = PageRequest.of(page, 10, Sort.by("faqId").descending());

        // 키워드가 있으면 검색, 없으면 전체 조회
        Page<Faq> faqPage = (keyword != null && !keyword.isEmpty()) ?
                faqAdminService.search(keyword, pageable) :
                faqAdminService.findAllWithPaging(pageable);

        // 뷰로 전달할 데이터 설정
        model.addAttribute("faqPage", faqPage);
        model.addAttribute("keyword", keyword);
        model.addAttribute("currentPage", "faq-list");

        // FlashAttribute로 전달된 메시지 처리
        if (successMessage != null && !successMessage.isEmpty()) {
            model.addAttribute("successMessage", successMessage);
        }
        if (errorMessage != null && !errorMessage.isEmpty()){
            model.addAttribute("errorMessage", errorMessage);
        }

        return "admin/faq/list";
    }

    /**
     * FAQ 등록 폼 페이지
     * - CS 또는 SUPER 관리자만 접근 가능
     */
    @GetMapping("/add")
    public String addForm(HttpSession session, Model model) {
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");

        // 권한 체크
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            model.addAttribute("errorMessage", "CS 권한이 있는 관리자만 등록 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        return "admin/faq/add";
    }

    /**
     * FAQ 등록 처리
     */
    @PostMapping("/add")
    public String addFaq(@RequestParam("question") String question,
                         @RequestParam("answer") String answer,
                         @RequestParam(value = "active", required = false) String active,
                         HttpSession session,
                         RedirectAttributes redirectAttributes) {

        // 관리자 권한 확인
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 등록 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        // FAQ 엔티티 생성 및 값 세팅
        Faq faq = new Faq();
        faq.setQuestion(question);
        faq.setAnswer(answer);
        faq.setActive(active != null && active.equals("on"));

        // 저장 시도
        try {
            faqAdminService.save(faq);
            redirectAttributes.addFlashAttribute("successMessage", "FAQ가 등록되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 저장 중 오류가 발생했습니다.");
        }

        return "redirect:/admin/faq/list";
    }

    /**
     * FAQ 수정 폼 페이지
     */
    @GetMapping("/edit/{id}")
    public String editForm(@PathVariable("id") Integer id,
                           Model model,
                           HttpSession session,
                           RedirectAttributes redirectAttributes) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");

        // 권한 체크
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 접근 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        try {
            // FAQ 조회
            Faq faq = faqAdminService.findById(id);
            if (faq == null){
                redirectAttributes.addFlashAttribute("errorMessage", "해당 FAQ가 존재하지 않습니다.");
                return "redirect:/admin/faq/list";
            }

            // 수정 폼에 데이터 전달
            model.addAttribute("faq", faq);
            return "admin/faq/edit";

        } catch (Exception e){
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 로딩 중 오류가 발생했습니다.");
            return "redirect:/admin/faq/list";
        }
    }

    /**
     * FAQ 수정 처리
     */
    @PostMapping("/edit/{id}")
    public String editFaq(@PathVariable("id") Integer id,
                          @RequestParam("question") String question,
                          @RequestParam("answer") String answer,
                          @RequestParam(value = "active", required = false) String active,
                          HttpSession session,
                          RedirectAttributes redirectAttributes) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");

        // 권한 체크
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 수정 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        Faq existing;

        // 기존 FAQ 조회
        try {
            existing = faqAdminService.findById(id);
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 조회 중 오류가 발생했습니다.");
            return "redirect:/admin/faq/list";
        }

        // 값 변경
        existing.setQuestion(question);
        existing.setAnswer(answer);
        existing.setActive(active != null && active.equals("on"));

        // 저장
        try {
            faqAdminService.save(existing);
            redirectAttributes.addFlashAttribute("successMessage", "FAQ가 수정되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 수정 중 오류가 발생했습니다.");
        }

        return "redirect:/admin/faq/list";
    }

    /**
     * FAQ 삭제 처리
     */
    @PostMapping("/delete/{id}")
    public String deleteFaq(@PathVariable("id") Integer id,
                            HttpSession session,
                            RedirectAttributes redirectAttributes) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");

        // 권한 체크
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 삭제 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        try {
            faqAdminService.delete(id);
            redirectAttributes.addFlashAttribute("successMessage", "FAQ가 성공적으로 삭제되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 삭제 중 오류가 발생했습니다.");
        }

        return "redirect:/admin/faq/list";
    }
}
