package com.example.fund.admin.approval.controller;

import com.example.fund.admin.approval.entity.Approval;
import com.example.fund.admin.approval.entity.ApprovalLog;
import com.example.fund.admin.approval.service.ApprovalLogService;
import com.example.fund.admin.approval.service.ApprovalService;
import com.example.fund.admin.dto.AdminDTO;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

/**
 * 결재(Approval) 관련 관리자 화면 요청을 처리하는 컨트롤러
 * - 결재 목록 조회
 * - 승인 / 반려 / 배포
 * - 결재 요청 등록 및 수정
 */
@Controller
@RequestMapping("/admin/approval")
@RequiredArgsConstructor
public class ApprovalController {

    // 결재 비즈니스 로직
    private final ApprovalService approvalService;

    // 결재 로그 조회용 서비스
    private final ApprovalLogService approvalLogService;

    /**
     * 결재 관리 메인 페이지
     * - 결재대기 / 배포대기 / 반려 상태별 목록 조회
     * - super, approver 권한만 접근 가능
     */
    @GetMapping("/manage")
    public String manageApprovals(HttpSession session, Model model,
                                  @RequestParam(defaultValue = "0") int pendingPage,
                                  @RequestParam(defaultValue = "0") int readyPage,
                                  @RequestParam(defaultValue = "0") int rejectedPage) {

        // 로그인 관리자 확인
        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) return "redirect:/admin/";

        // 권한 체크 (조회는 허용하되 메시지 표시)
        if (!"super".equals(admin.getRole()) && !"approver".equals(admin.getRole())) {
            model.addAttribute("msg", "승인 권한이 없습니다.");
        }

        // 상태별 결재 목록 조회 (페이지네이션)
        var pending = approvalService.getApprovalsByStatus("결재대기", pendingPage);
        var waiting = approvalService.getApprovalsByStatus("배포대기", readyPage);
        var rejected = approvalService.getApprovalsByStatus("반려", rejectedPage);

        // 목록 데이터 전달
        model.addAttribute("pendingPage", pending);
        model.addAttribute("readyPage", waiting);
        model.addAttribute("rejectedPage", rejected);

        // 요약 바에 표시할 전체 건수
        model.addAttribute("pendingTotal", pending.getTotalElements());
        model.addAttribute("waitingTotal", waiting.getTotalElements());
        model.addAttribute("rejectedTotal", rejected.getTotalElements());

        // 로그인 관리자 역할
        model.addAttribute("adminRole", admin.getRole());

        return "admin/approval/manage";
    }

    /**
     * 결재 승인 처리
     * - approver / super / planner 권한만 가능
     * - 승인 사유(reason) optional
     */
    @PostMapping("/approve/{id}")
    public String approve(@PathVariable Integer id,
                          @RequestParam(required = false) String reason,
                          HttpSession session,
                          RedirectAttributes redirect) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) return "redirect:/admin/";

        // 컨트롤러 레벨 권한 체크
        if (!List.of("super", "approver", "planner").contains(admin.getRole())) {
            redirect.addFlashAttribute("alertMessage", "승인 권한이 없습니다.");
            return "redirect:/admin/approval/manage";
        }

        try {
            // 승인 처리 (권한은 role로 전달)
            approvalService.approve(id, admin.getRole(), reason);
            redirect.addFlashAttribute("alertMessage", "승인 처리되었습니다.");
        } catch (SecurityException ex) {
            redirect.addFlashAttribute("alertMessage", ex.getMessage());
        } catch (Exception ex) {
            ex.printStackTrace();
            redirect.addFlashAttribute("alertMessage", "승인 중 시스템 오류가 발생했습니다.");
        }

        return "redirect:/admin/approval/manage";
    }

    /**
     * 결재 반려 처리
     * - 반려 사유 필수
     */
    @PostMapping("/reject/{id}")
    public String reject(@PathVariable("id") Integer id,
                         @RequestParam("reason") String reason,
                         HttpSession session,
                         RedirectAttributes rttr) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) return "redirect:/admin/";

        try {
            approvalService.reject(id, reason, admin.getRole());
            rttr.addFlashAttribute("msg", "반려 완료");
        } catch (SecurityException e) {
            rttr.addFlashAttribute("msg", "반려 권한이 없습니다.");
        } catch (IllegalStateException | IllegalArgumentException e) {
            rttr.addFlashAttribute("msg", "반려 불가 상태입니다: " + e.getMessage());
        } catch (Exception e) {
            e.printStackTrace();
            rttr.addFlashAttribute("msg", "반려 중 오류 발생");
        }

        return "redirect:/admin/approval/manage";
    }

    /**
     * 배포 처리
     * - planner 권한만 가능
     * - 배포 후 펀드 상세 페이지로 이동
     */
    @PostMapping("/publish/{id}")
    public String publish(@PathVariable("id") Integer id,
                          HttpSession session,
                          RedirectAttributes redirectAttributes) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) return "redirect:/admin/";

        // 배포 권한 체크
        if (!"planner".equals(admin.getRole())) {
            redirectAttributes.addFlashAttribute("alertMessage", "배포 권한이 없습니다.");
            return "redirect:/admin/approval/manage";
        }

        try {
            approvalService.publish(id, admin.getAdminname());
            redirectAttributes.addFlashAttribute("successMessage", "성공적으로 배포되었습니다.");

            // 배포 완료 후 해당 펀드 상세 페이지로 이동
            Approval approval = approvalService.findById(id);
            if (approval != null && approval.getFund() != null) {
                return "redirect:/admin/fund/view/" + approval.getFund().getFundId();
            }
        } catch (Exception e) {
            e.printStackTrace();
            redirectAttributes.addFlashAttribute("alertMessage", "배포 처리 중 오류가 발생했습니다.");
        }

        return "redirect:/admin/approval/my-list";
    }

    /**
     * 내가 작성한 결재 목록 조회
     * - 상태별로 분리하여 조회
     */
    @GetMapping({"/my-list", "/list"})
    public String getMyApprovals(HttpSession session, Model model,
                                 @RequestParam(defaultValue = "0") int pendingPage,
                                 @RequestParam(defaultValue = "0") int waitingPage,
                                 @RequestParam(defaultValue = "0") int rejectedPage,
                                 @RequestParam(defaultValue = "0") int publishedPage) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) return "redirect:/admin/";

        String adminname = admin.getAdminname();

        model.addAttribute("pendingPage", approvalService.getApprovalsByStatus(adminname, "결재대기", pendingPage));
        model.addAttribute("waitingPage", approvalService.getApprovalsByStatus(adminname, "배포대기", waitingPage));
        model.addAttribute("rejectedPage", approvalService.getApprovalsByStatus(adminname, "반려", rejectedPage));
        model.addAttribute("publishedPage", approvalService.getApprovalsByStatus(adminname, "배포", publishedPage));

        // 요약 수치
        model.addAttribute("pendingTotal", approvalService.getApprovalsByStatus(adminname, "결재대기", 0).getTotalElements());
        model.addAttribute("waitingTotal", approvalService.getApprovalsByStatus(adminname, "배포대기", 0).getTotalElements());
        model.addAttribute("rejectedTotal", approvalService.getApprovalsByStatus(adminname, "반려", 0).getTotalElements());
        model.addAttribute("publishedTotal", approvalService.getApprovalsByStatus(adminname, "배포", 0).getTotalElements());

        model.addAttribute("adminRole", admin.getRole());

        return "admin/approval/list";
    }

    /**
     * 결재 상세 조회
     * - 결재 정보 + 로그 조회
     */
    @GetMapping("/detail/{id}")
    public String viewDetail(@PathVariable("id") Integer id, HttpSession session, Model model) {

        AdminDTO admin = (AdminDTO) session.getAttribute("admin");
        if (admin == null) return "redirect:/admin/";

        Approval approval = approvalService.findById(id);
        if (approval == null) {
            model.addAttribute("msg", "존재하지 않는 결재 요청입니다.");
            return "redirect:/admin/approval/my-list";
        }

        // 결재 로그 조회
        List<ApprovalLog> logs = approvalLogService.getLogsByApprovalId(id);

        model.addAttribute("approval", approval);
        model.addAttribute("logs", logs);
        model.addAttribute("admin", admin);

        return "admin/approval/detail";
    }
}
