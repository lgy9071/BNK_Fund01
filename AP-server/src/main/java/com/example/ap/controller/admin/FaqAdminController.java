package com.example.ap.controller.admin;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.ap.service.admin.FaqAdminService;
import com.example.common.dto.admin.AdminDTO;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

@Controller
@RequiredArgsConstructor
@RequestMapping("/admin/faq")
public class FaqAdminController {

    private final FaqAdminService faqAdminService;

    @GetMapping("/list")
    public String faqList(@RequestParam(value = "keyword", required = false) String keyword,
                          @RequestParam(defaultValue = "0") int page,
                          Model model, HttpSession session,
                          @ModelAttribute("successMessage") String successMessage,
                          @ModelAttribute("errorMessage") String errorMessage) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        model.addAttribute("admin", admin);

        Pageable pageable = PageRequest.of(page, 10, Sort.by("faqId").descending());
        Page<Faq> faqPage = (keyword != null && !keyword.isEmpty()) ?
                faqAdminService.search(keyword, pageable) :
                faqAdminService.findAllWithPaging(pageable);

        model.addAttribute("faqPage", faqPage);
        model.addAttribute("keyword", keyword);
        model.addAttribute("currentPage", "faq-list");
        if (successMessage != null && !successMessage.isEmpty()) {
            model.addAttribute("successMessage", successMessage);
        }
        if (errorMessage != null && !errorMessage.isEmpty()){
            model.addAttribute("errorMessage", errorMessage);
        }
        return "admin/faq/list";
    }

    @GetMapping("/add")
    public String addForm(HttpSession session, Model model) {
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            model.addAttribute("errorMessage", "CS 권한이 있는 관리자만 등록 가능합니다.");
            return "redirect:/admin/faq/list";
        }
        return "admin/faq/add";
    }

    @PostMapping("/add")
    public String addFaq(@RequestParam("question") String question,
                         @RequestParam("answer") String answer,
                         @RequestParam(value = "active", required = false) String active,
                         HttpSession session,
                         RedirectAttributes redirectAttributes) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 등록 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        Faq faq = new Faq();
        faq.setQuestion(question);
        faq.setAnswer(answer);
        faq.setActive(active != null && active.equals("on"));

        try {
            faqAdminService.save(faq);
            redirectAttributes.addFlashAttribute("successMessage", "FAQ가 등록되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 저장 중 오류가 발생했습니다.");
        }

        return "redirect:/admin/faq/list";
    }

    @GetMapping("/edit/{id}")
    public String editForm(@PathVariable("id") Integer id, Model model, HttpSession session, RedirectAttributes redirectAttributes) {
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");

        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 접근 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        try{
            Faq faq = faqAdminService.findById(id);
            if (faq == null){
                redirectAttributes.addFlashAttribute("errorMessage", "해당 FAQ가 존재하지 않습니다.");
                return "redirect:/admin/faq/list";
            }
            model.addAttribute("faq", faq);
            return "admin/faq/edit";
        } catch (Exception e){
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 로딩 중 오류가 발생했습니다.");
            return "redirect:/admin/faq/list";
        }
    }

    @PostMapping("/edit/{id}")
    public String editFaq(@PathVariable("id") Integer id,
                          @RequestParam("question") String question,
                          @RequestParam("answer") String answer,
                          @RequestParam(value = "active", required = false) String active,
                          HttpSession session,
                          RedirectAttributes redirectAttributes) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null || !List.of("cs", "super").contains(admin.getRole())) {
            redirectAttributes.addFlashAttribute("errorMessage", "CS 권한이 있는 관리자만 수정 가능합니다.");
            return "redirect:/admin/faq/list";
        }

        Faq existing;
        try {
            existing = faqAdminService.findById(id);
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 조회 중 오류가 발생했습니다.");
            return "redirect:/admin/faq/list";
        }

        existing.setQuestion(question);
        existing.setAnswer(answer);
        existing.setActive(active != null && active.equals("on"));

        try {
            faqAdminService.save(existing);
            redirectAttributes.addFlashAttribute("successMessage", "FAQ가 수정되었습니다.");
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("errorMessage", "FAQ 수정 중 오류가 발생했습니다.");
        }
        redirectAttributes.addFlashAttribute("successMessage", "FAQ가 수정되었습니다.");
        return "redirect:/admin/faq/list";
    }

    @PostMapping("/delete/{id}")
    public String deleteFaq(@PathVariable("id") Integer id,
                            HttpSession session,
                            RedirectAttributes redirectAttributes) {
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");

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
