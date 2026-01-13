package com.example.fund.admin.controller;

import com.example.fund.admin.approval.entity.Approval;
import com.example.fund.admin.approval.service.ApprovalService;
import com.example.fund.admin.dto.AdminDTO;
import com.example.fund.admin.faq.service.FaqAdminService;
import com.example.fund.admin.notice.dto.AdminNoticeDTO;
import com.example.fund.admin.notice.service.AdminNoticeService;
import com.example.fund.admin.service.AdminDashboardService;
import com.example.fund.fund.service.FundService;
import com.example.fund.qna.service.QnaService;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.*;


@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class DashboardController {

    /* =========================
     * 의존성 주입(Service Layer)
     * ========================= */

    // 미답변 QnA 개수, 최근 미답변 조회용
    private final QnaService qnaService;

    // 결재 문서 상태 조회, 통계 계산용
    private final ApprovalService approvalService;

    // 관리자 공지사항 조회용
    private final AdminNoticeService noticeService;

    // FAQ 관리 및 카테고리별 통계용
    private final FaqAdminService faqAdminService;

    // 대시보드 전용 종합 통계 서비스 (현재 일부 주석 처리됨)
    private final AdminDashboardService dashSvc;

    /* =========================
     * 관리자 대시보드 메인
     * ========================= */
    @GetMapping("/dashboard")
    public String dashboard(HttpSession session, Model model) {

        /* ---------- 1. 로그인 체크 ---------- */
        // 세션에 관리자 정보가 없으면 로그인 페이지로 리다이렉트
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) {
            return "redirect:/admin/";
        }

        // 관리자 권한(role) 추출 → 화면에서 권한별 분기 렌더링에 사용
        String role = admin.getRole();
        model.addAttribute("role", role);

        /* ---------- 2. 공통 영역 : 최근 관리자 공지 ---------- */
        // 대시보드 상단에 표시할 최근 공지사항 5개
        List<AdminNoticeDTO> recentNotices =
                noticeService.findRecentAdminNotices(5);
        model.addAttribute("recentNotices", recentNotices);

        /* ---------- 3. CS / Super : 미답변 문의 ---------- */
        // 고객센터(cs)와 최고관리자(super)만 접근 가능
        if ("cs".equals(role) || "super".equals(role)) {

            // 미답변 문의 개수
            Integer unCnt = qnaService.countUnanwseQna();
            model.addAttribute("unansweredCount", unCnt);

            // 최근 미답변 문의 5건
            model.addAttribute("recentUnanswered",
                    qnaService.findRecentUnanswered(5));
        }

        /* ---------- 4. Planner / Super : 내가 올린 결재 중 대기 ---------- */
        // 기안자(planner)와 super 권한만 조회 가능
        if ("planner".equals(role) || "super".equals(role)) {

            // 내가 작성한 문서 중 '결재대기' 상태 개수
            Integer myPending = (int) approvalService
                    .getApprovalsByStatus(
                            admin.getAdminname(), // 작성자
                            "결재대기",           // 상태
                            0                     // 페이지 번호
                    )
                    .getTotalElements();

            model.addAttribute("myPendingCount", myPending);

            // 최근 결재 요청 목록 (오류로 임시 비활성화)
            // model.addAttribute("recentMyRequests",
            //         approvalService.findRecentByWriter(admin.getAdminname(), 5));
        }

        /* ---------- 5. Approver / Super : 승인 대기 문서 ---------- */
        if ("approver".equals(role) || "super".equals(role)) {

            // 전체 결재대기 문서 수
            Integer waiting = (int) approvalService
                    .getApprovalsByStatus("결재대기", 0)
                    .getTotalElements();

            model.addAttribute("waitingApproveCount", waiting);

            // 가장 오래된 결재 문서 목록 (임시 주석)
            // model.addAttribute("oldestApprovals",
            //         approvalService.findOldestApprovals("결재대기", 5));

            // 전체 평균 결재 소요 일수
            model.addAttribute("avgApprovalDays",
                    approvalService.calculateAverageApprovalDays());

            // 승인자 기준 결재 상태 요약 (대기/승인/반려)
            Map<String, Integer> approverStatusSummary =
                    approvalService.getStatusSummaryForApprover();
            model.addAttribute("approverStatusSummary",
                    approverStatusSummary);
        }

        /* ---------- 6. Super 전용 통계 (현재 비활성화) ---------- */
        // 결재 흐름 전체 요약, FAQ 총 개수 등
        // if ("super".equals(role)) {
        //     Map<String, Integer> flowSummary =
        //             approvalService.getFlowSummary();
        //     model.addAttribute("flowSummary", flowSummary);
        //
        //     Integer faqCount =
        //             (int) faqAdminService.countAllFaqs();
        //     model.addAttribute("faqCount", faqCount);
        //
        //     dashSvc.populateSuperMetrics(model);
        // }

        /* ---------- 7. Super / CS : FAQ 카테고리별 통계 ---------- */
        if ("super".equals(role) || "cs".equals(role)) {
            Map<String, Integer> faqCategoryCounts =
                    faqAdminService.getFaqCountsByCategory();
            model.addAttribute("faqCategoryCounts",
                    faqCategoryCounts);
        }

        /* ---------- 8. Planner / Super : 내 결재 이력 요약 ---------- */
        if ("planner".equals(role) || "super".equals(role)) {

            // 내 결재 상태별 요약 (대기/승인/반려)
            Map<String, Integer> myStatusSummary =
                    approvalService.getStatusSummaryByWriter(
                            admin.getAdminname());
            model.addAttribute("myStatusSummary",
                    myStatusSummary);

            // 최근 반려된 문서 5건
            List<Approval> recentRejected =
                    approvalService.findRecentRejectedByWriter(
                            admin.getAdminname(), 5);
            model.addAttribute("recentRejected", recentRejected);

            // 평균 결재 소요 일수 (내 기준)
            double myAvgDuration =
                    approvalService.calculateAvgDaysByWriter(
                            admin.getAdminname());
            model.addAttribute("myAvgDuration", myAvgDuration);
        }

        /* ---------- 9. Null 방지용 기본값 세팅 ---------- */
        // Thymeleaf 렌더링 시 권한별 미사용 속성으로 인한 NPE 방지

        // CS 전용 속성
        if (!("cs".equals(role) || "super".equals(role))) {
            model.addAttribute("unansweredCount", 0);
            model.addAttribute("recentUnanswered", List.of());
            model.addAttribute("longPendingCount", 0);
            model.addAttribute("oldestUnanswered", null);
            model.addAttribute("oldestDuration", 0);
        }

        // FAQ 카테고리
        if (!("super".equals(role) || "cs".equals(role))) {
            model.addAttribute("faqCategoryCounts",
                    Collections.emptyMap());
        }

        // Planner 전용 속성
        if (!("planner".equals(role) || "super".equals(role))) {
            model.addAttribute("myStatusSummary",
                    Collections.emptyMap());
            model.addAttribute("recentRejected", List.of());
            model.addAttribute("myAvgDuration", 0.0);
            model.addAttribute("recentMyRequests", List.of());
            model.addAttribute("myPendingCount", 0);
        }

        // Approver 전용 속성
        if (!("approver".equals(role) || "super".equals(role))) {
            model.addAttribute("waitingApproveCount", 0);
            model.addAttribute("oldestApprovals", List.of());
            model.addAttribute("avgApprovalDays", 0.0);
            model.addAttribute("approverStatusSummary",
                    Collections.emptyMap());
        }

        /* ---------- 10. 대시보드 화면 반환 ---------- */
        return "admin/main";
    }

    /* =========================
     * 권한별 바로가기 링크 생성
     * ========================= */
    private List<QuickLink> buildQuickLinks(String role) {
        List<QuickLink> links = new ArrayList<>();

        // 모든 관리자 공통 링크
        links.add(new QuickLink(
                "/admin/report/daily",
                "fas fa-file-alt",
                "일간 보고서"
        ));

        // 권한별 추가 링크
        switch (role) {
            case "cs" -> {
                links.add(new QuickLink("/admin/qnaList",
                        "far fa-comment-dots", "문의 목록"));
                links.add(new QuickLink("/admin/faq/list",
                        "fas fa-question", "FAQ 관리"));
            }
            case "planner" -> {
                links.add(new QuickLink("/admin/approval/list",
                        "fas fa-file-signature", "내 결재 요청"));
                links.add(new QuickLink("/admin/approval/form",
                        "fas fa-plus-circle", "새 기안 등록"));
            }
            case "approver" -> {
                links.add(new QuickLink("/admin/approval/manage",
                        "fas fa-gavel", "승인 관리"));
            }
            case "super" -> {
                links.add(new QuickLink("/admin/fund/list",
                        "fas fa-chart-bar", "펀드 목록"));
                links.add(new QuickLink("/admin/approval/manage",
                        "fas fa-check-double", "결재 승인"));
                links.add(new QuickLink("/admin/qnaList",
                        "far fa-comment-dots", "1:1 문의"));
                links.add(new QuickLink("/admin/faq/list",
                        "fas fa-question", "FAQ 관리"));
            }
        }
        return links;
    }

    /* =========================
     * 대시보드 퀵링크 DTO
     * ========================= */
    public record QuickLink(String url, String icon, String label) {}
}
