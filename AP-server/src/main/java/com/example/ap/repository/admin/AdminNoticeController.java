package com.example.ap.repository.admin;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.ap.service.admin.AdminNoticeService;
import com.example.common.dto.admin.AdminDTO;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

@Controller
@RequestMapping("/admin/notice")
@RequiredArgsConstructor
public class AdminNoticeController {
    private final AdminNoticeService noticeService;

    // 공통 권한 체크 유틸
    private boolean isSuper(HttpSession session) {
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        return admin != null && "super".equals(admin.getRole());
    }

    // (1) 공지 등록 폼 (super 전용) get
    @GetMapping("/new")
    public String newForm(HttpSession session, RedirectAttributes rttr) {
        if (!isSuper(session)) {
            rttr.addFlashAttribute("alertMessage", "권한이 없습니다.");
            return "redirect:/admin/notice/list";
        }
        return "admin/notice/form";
    }

    // (2) 공지 등록 처리 post
    @PostMapping("/new")
    public String create(@RequestParam("title") String title,
                         @RequestParam("content") String content,
                         HttpSession session,
                         RedirectAttributes rttr) {
        if (!isSuper(session)) {
            rttr.addFlashAttribute("alertMessage", "권한이 없습니다.");
            return "redirect:/admin/notice/list";
        }
        noticeService.createAdminNotice(title, content, "super");
        rttr.addFlashAttribute("successMessage", "공지 등록되었습니다.");
        return "redirect:/admin/notice/list";
    }

    // (3) 전체 목록
    @GetMapping("/list")
    public String list(Model model, HttpSession session) {
        model.addAttribute("allNotices", noticeService.findRecentAdminNotices(50));
        // 대시보드에서 넘어오는 role 속성 그대로 재활용
        AdminDTO adm = (AdminDTO) session.getAttribute("admin");
        model.addAttribute("role", adm != null ? adm.getRole() : "");
        return "admin/notice/list";
    }

    // (4) 상세 페이지
    @GetMapping("/detail/{id}")
    public String detail(@PathVariable("id") Long id,
                         HttpSession session,
                         Model model) {
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) {
            return "redirect:/admin/";
        }
        // role 넣기
        model.addAttribute("role", admin.getRole());

        // notice 데이터
        model.addAttribute("notice", noticeService.findById(id));
        return "admin/notice/detail";
    }

    // (5) 수정 폼
    @GetMapping("/edit/{id}")
    public String editForm(@PathVariable("id") Long id, HttpSession session, RedirectAttributes rttr, Model model) {
        if (!isSuper(session)) {
            rttr.addFlashAttribute("alertMessage", "권한이 없습니다.");
            return "redirect:/admin/notice/list";
        }
        model.addAttribute("notice", noticeService.findById(id));
        return "admin/notice/form";
    }

    // (6) 수정 처리
    @PostMapping("/edit/{id}")
    public String update(@PathVariable("id") Long id,
                         @RequestParam("title") String title,
                         @RequestParam("content") String content,
                         HttpSession session,
                         RedirectAttributes rttr) {
        if (!isSuper(session)) {
            rttr.addFlashAttribute("alertMessage", "권한이 없습니다.");
            return "redirect:/admin/notice/list";
        }
        noticeService.updateAdminNotice(id, title, content);
        rttr.addFlashAttribute("successMessage", "공지 수정되었습니다.");
        return "redirect:/admin/notice/list";
    }

    // (7) 삭제 처리
    @PostMapping("/delete/{id}")
    public String delete(@PathVariable("id") Long id,
                         HttpSession session,
                         RedirectAttributes rttr) {
        if (!isSuper(session)) {
            rttr.addFlashAttribute("alertMessage", "권한이 없습니다.");
            return "redirect:/admin/notice/list";
        }
        noticeService.deleteAdminNotice(id);
        rttr.addFlashAttribute("successMessage", "공지 삭제되었습니다.");
        return "redirect:/admin/notice/list";
    }
}
