package com.example.ap.controller.admin;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import com.example.ap.service.admin.AdminDashboardService;
import com.example.ap.service.admin.AdminNoticeService;
import com.example.ap.service.admin.ApprovalService;
import com.example.ap.service.admin.FaqAdminService;
import com.example.ap.service.fund.QnaService;
import com.example.common.dto.admin.AdminDTO;
import com.example.common.dto.admin.AdminNoticeDTO;
import com.example.common.entity.admin.Approval;

import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;


@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class DashboardController {

    private final QnaService           qnaService;       // countUnanwseQna() 사용
    private final ApprovalService      approvalService;  // getApprovalsByStatus() 사용
    private final AdminNoticeService noticeService;    // 최근 공지 조회용
    private final FaqAdminService faqAdminService;
    private final AdminDashboardService dashSvc;

    @GetMapping("/dashboard")
    public String dashboard(HttpSession session, Model model) {
        // 로그인 체크
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) {
            return "redirect:/admin/";
        }
        String role = admin.getRole();
        model.addAttribute("role", role);

        // 최근 공지
        List<AdminNoticeDTO> recentNotices = noticeService.findRecentAdminNotices(5);
        model.addAttribute("recentNotices", recentNotices);

        // CS + super: 미답변 문의
        if ("cs".equals(role) || "super".equals(role)) {
            Integer unCnt = qnaService.countUnanwseQna();
            model.addAttribute("unansweredCount", unCnt);
            model.addAttribute("recentUnanswered", qnaService.findRecentUnanswered(5));
        }

        // Planner + super: 내 결재 대기
        if ("planner".equals(role) || "super".equals(role)) {
            Integer myPending = (int) approvalService
                    .getApprovalsByStatus(admin.getAdminname(), "결재대기", 0)
                    .getTotalElements();
            model.addAttribute("myPendingCount", myPending);
            model.addAttribute("recentMyRequests",
                    approvalService.findRecentByWriter(admin.getAdminname(), 5));
        }

        // Approver + super: 승인 대기
        if ("approver".equals(role) || "super".equals(role)) {
            Integer waiting = (int) approvalService
                    .getApprovalsByStatus("결재대기", 0)
                    .getTotalElements();
            model.addAttribute("waitingApproveCount", waiting);

            model.addAttribute("oldestApprovals",
                    approvalService.findOldestApprovals("결재대기", 5));
            model.addAttribute("avgApprovalDays",
                    approvalService.calculateAverageApprovalDays());

            Map<String, Integer> approverStatusSummary =
                    approvalService.getStatusSummaryForApprover();  // (새 메소드 또는 기존 서비스 메소드)
            model.addAttribute("approverStatusSummary", approverStatusSummary);
        }

        // Super 전용: 결재 흐름 요약, FAQ 건수
        if ("super".equals(role)) {
            Map<String, Integer> flowSummary = approvalService.getFlowSummary();
            model.addAttribute("flowSummary", flowSummary);

            Integer faqCount = (int) faqAdminService.countAllFaqs();
            model.addAttribute("faqCount", faqCount);
            dashSvc.populateSuperMetrics(model);
        }

        // 관리자(super) + CS 권한: FAQ 카테고리별 집계
        if ("super".equals(role) || "cs".equals(role)) {
            Map<String, Integer> faqCategoryCounts = faqAdminService.getFaqCountsByCategory();
            model.addAttribute("faqCategoryCounts", faqCategoryCounts);
        }

        // Planner 또는 Super용: 결재 상태별 요약, 반려 내역, 평균 소요시간
        if ("planner".equals(role) || "super".equals(role)) {
            Map<String, Integer> myStatusSummary = approvalService.getStatusSummaryByWriter(admin.getAdminname());
            model.addAttribute("myStatusSummary", myStatusSummary);

            List<Approval> recentRejected = approvalService.findRecentRejectedByWriter(admin.getAdminname(), 5);
            model.addAttribute("recentRejected", recentRejected);

            double myAvgDuration = approvalService.calculateAvgDaysByWriter(admin.getAdminname());
            model.addAttribute("myAvgDuration", myAvgDuration);
        }

        // null 방지를 위한 기본값 채우기
        // 1) CS 전용 속성
        if (!("cs".equals(role) || "super".equals(role))) {
            model.addAttribute("unansweredCount", 0);
            model.addAttribute("recentUnanswered", List.of());
            model.addAttribute("longPendingCount", 0);
            model.addAttribute("oldestUnanswered", null);
            model.addAttribute("oldestDuration", 0);
        }
        // 2) FAQ 카테고리 (super·cs 외에는 빈 Map)
        if (!("super".equals(role) || "cs".equals(role))) {
            model.addAttribute("faqCategoryCounts", Collections.emptyMap());
        }
        // 3) Planner 전용 속성
        if (!("planner".equals(role) || "super".equals(role))) {
            model.addAttribute("myStatusSummary", Collections.emptyMap());
            model.addAttribute("recentRejected", List.of());
            model.addAttribute("myAvgDuration", 0.0);
            model.addAttribute("recentMyRequests", List.of());
            model.addAttribute("myPendingCount", 0);
        }
        // 4) Approver 전용 속성
        if (!("approver".equals(role) || "super".equals(role))) {
            model.addAttribute("waitingApproveCount", 0);
            model.addAttribute("oldestApprovals", List.of());
            model.addAttribute("avgApprovalDays", 0.0);

            model.addAttribute("approverStatusSummary", Collections.emptyMap());
        }

        return "admin/main";
    }

    /* ===== 링크 빌더 ===== */
    private List<QuickLink> buildQuickLinks(String role) {
        List<QuickLink> links = new ArrayList<>();
        links.add(new QuickLink("/admin/report/daily", "fas fa-file-alt", "일간 보고서"));
        switch (role) {
            case "cs" -> {
                links.add(new QuickLink("/admin/qnaList",    "far fa-comment-dots", "문의 목록"));
                links.add(new QuickLink("/admin/faq/list",   "fas fa-question",     "FAQ 관리"));
            }
            case "planner" -> {
                links.add(new QuickLink("/admin/approval/list", "fas fa-file-signature", "내 결재 요청"));
                links.add(new QuickLink("/admin/approval/form", "fas fa-plus-circle",    "새 기안 등록"));
            }
            case "approver" -> {
                links.add(new QuickLink("/admin/approval/manage", "fas fa-gavel", "승인 관리"));
            }
            case "super" -> {
                links.add(new QuickLink("/admin/fund/list",       "fas fa-chart-bar", "펀드 목록"));
                links.add(new QuickLink("/admin/approval/manage", "fas fa-check-double", "결재 승인"));
                links.add(new QuickLink("/admin/qnaList",         "far fa-comment-dots", "1:1 문의"));
                links.add(new QuickLink("/admin/faq/list",        "fas fa-question",     "FAQ 관리"));
            }
        }
        return links;
    }

    /* ===== QuickLink DTO ===== */
    public record QuickLink(String url, String icon, String label) {}
}
