package com.example.fund.admin.approval.service;

import com.example.fund.admin.approval.entity.Approval;
import com.example.fund.admin.approval.repository.ApprovalRepository;
import com.example.fund.admin.entity.Admin;
import com.example.fund.admin.repository.AdminRepository_A;
import com.example.fund.admin.repository.projection.StatusCount;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.repository_fund.FundRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ApprovalService {

    private final ApprovalRepository approvalRepository;
    private final AdminRepository_A adminRepository;
    private final ApprovalLogService approvalLogService; // 결재 상태 변경 이력 기록
    private final FundRepository fundRepository;

    /**
     * 승인/반려가 가능한 역할 목록
     * → 권한 체크 시 공통 사용
     */
    private static final List<String> APPROVER_ROLES =
            List.of("super", "approver", "planner");

    /* ==================================================
     * 1. 내 결재 목록 (요청자)
     * ================================================== */

    /**
     * 요청자 기준 진행 중 결재 목록 조회
     * - 배포, 반려 상태는 제외
     */
    public Page<Approval> getMyApprovals(String adminname, Pageable pageable) {
        List<String> exclude = List.of("배포", "반려");
        return approvalRepository.findByWriterAdminnameAndStatusNotIn(
                adminname, exclude, pageable);
    }

    /* ==================================================
     * 2. 전체 결재 목록 (승인자)
     * ================================================== */

    /**
     * 승인자/관리자용 전체 결재 목록 조회
     * - status가 있으면 해당 상태만
     * - 없으면 전체 조회
     */
    public Page<Approval> getAllApprovals(String status, Pageable pageable) {
        return (status != null && !status.isBlank())
                ? approvalRepository.findByStatus(status, pageable)
                : approvalRepository.findAll(pageable);
    }

    /* ==================================================
     * 3. 승인 처리
     * ================================================== */

    /**
     * 결재 승인 처리
     * - 승인 권한 역할인지 확인
     * - 현재 상태가 "결재대기"인지 검증
     * - 상태를 "배포대기"로 변경
     * - 승인 로그 기록
     */
    public void approve(Integer approvalId, String role, String reason) {

        if (!APPROVER_ROLES.contains(role))
            throw new SecurityException("승인 권한이 없습니다.");

        Approval approval = approvalRepository.findById(approvalId)
                .orElseThrow(() -> new IllegalArgumentException("결재 요청 없음"));

        if (!"결재대기".equals(
                approval.getStatus() != null ? approval.getStatus().trim() : ""))
            throw new IllegalStateException("현재 상태에서 배포대기로 변경할 수 없습니다.");

        approval.setStatus("배포대기");
        approvalRepository.save(approval);

        // 상태 변경 이력 저장
        approvalLogService.saveLog(approval, role, "배포대기", reason);
    }

    /* ==================================================
     * 4. 반려 처리
     * ================================================== */

    /**
     * 결재 반려 처리
     * - 승인 권한 확인
     * - 결재대기 상태만 반려 가능
     * - 반려 사유 저장
     * - 로그 기록
     */
    public void reject(Integer id, String reason, String role) {

        if (!APPROVER_ROLES.contains(role))
            throw new SecurityException("반려 권한이 없습니다.");

        Approval approval = approvalRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("결재 없음"));

        if (!"결재대기".equals(approval.getStatus()))
            throw new IllegalStateException("현재 상태에서 반려할 수 없습니다.");

        approval.setStatus("반려");
        approval.setRejectReason(reason);
        approvalRepository.save(approval);

        approvalLogService.saveLog(approval, role, "반려", reason);
    }

    /* ==================================================
     * 5. 배포 처리 (요청자 본인)
     * ================================================== */

    /**
     * 배포 처리
     * - 작성자 본인만 가능
     * - 상태가 배포대기일 때만 가능
     */
    public void publish(Integer id, String adminname) {

        Approval approval = approvalRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("결재 없음"));

        if (approval.getWriter() == null ||
                !adminname.equals(approval.getWriter().getAdminname()))
            throw new SecurityException("배포 권한이 없습니다.");

        if (!"배포대기".equals(approval.getStatus()))
            throw new IllegalStateException("배포 가능한 상태가 아닙니다.");

        approval.setStatus("배포");
        approvalRepository.save(approval);

        approvalLogService.saveLog(approval, adminname, "배포", null);

        // TODO 실제 펀드 등록 등 후처리 로직 연결
    }

    /* ==================================================
     * 6. 결재 요청 등록
     * ================================================== */

    /**
     * 결재 요청 신규 생성
     * - 최초 상태는 "결재대기"
     * - 저장 후 생성된 approvalId 반환
     */
    @Transactional
    public Integer createApproval(String title, String content,
                                  Integer adminId, String fundId) {

        Admin writer = adminRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("작성자 정보 없음"));

        Fund fund = null;
        if (fundId != null) {
            fund = fundRepository.findById(fundId)
                    .orElseThrow(() -> new IllegalArgumentException("펀드 정보 없음"));
        }

        Approval approval = Approval.builder()
                .title(title)
                .content(content)
                .writer(writer)
                .fund(fund)
                .status("결재대기")
                .build();

        approvalRepository.save(approval);
        return approval.getApprovalId();
    }

    /* ==================================================
     * 7. 상태별 목록 조회
     * ================================================== */

    /**
     * 요청자 기준 상태별 결재 목록 조회
     */
    public Page<Approval> getApprovalsByStatus(String adminname,
                                               String status, int page) {
        Pageable pageable = PageRequest.of(
                page, 10, Sort.by("regDate").descending());

        return approvalRepository
                .findByWriterAdminnameAndStatus(adminname, status, pageable);
    }

    /**
     * 승인자 기준 상태별 결재 목록 조회
     */
    public Page<Approval> getApprovalsByStatus(String status, int page) {
        Pageable pageable = PageRequest.of(
                page, 10, Sort.by("regDate").descending());

        return approvalRepository.findByStatus(status, pageable);
    }

    /* ==================================================
     * 8. 기타 조회 / 수정
     * ================================================== */

    /**
     * 결재 상세 조회
     */
    public Approval findById(Integer id) {
        return approvalRepository.findById(id).orElse(null);
    }

    /**
     * 작성자 기준 전체 결재 목록 (페이징 없음)
     */
    public List<Approval> getApprovalsByWriter(String adminname) {
        return approvalRepository
                .findByWriterAdminname(adminname, Pageable.unpaged())
                .getContent();
    }

    /**
     * 반려된 결재 재기안 처리
     */
    public void updateApproval(Integer id, String title,
                               String content, String adminname) {

        Approval approval = approvalRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("해당 결재 요청 없음"));

        if (!adminname.equals(approval.getWriter().getAdminname()))
            throw new SecurityException("수정 권한이 없습니다.");

        if (!"반려".equals(approval.getStatus()))
            throw new IllegalStateException("반려 상태만 수정 가능");

        approval.setTitle(title);
        approval.setContent(content);
        approval.setStatus("결재대기");
        approval.setRejectReason(null);
        approvalRepository.save(approval);

        approvalLogService.saveLog(approval, adminname, "결재대기", "재기안");
    }

    /* ==================================================
     * 9. 통계 / 대시보드
     * ================================================== */

    /**
     * 평균 승인 처리 일수 계산
     * 기준: 등록일 → 배포대기 전환 시점
     */
    public Integer calculateAverageApprovalDays() {
        return (int) approvalLogService.findAllByNewStatus("배포대기").stream()
                .mapToLong(log ->
                        Duration.between(
                                log.getApproval().getRegDate(),
                                log.getChangedAt()
                        ).toDays()
                )
                .average()
                .orElse(0.0);
    }

    /**
     * 작성자 기준 상태별 결재 건수 요약
     */
    public Map<String, Integer> getStatusSummaryByWriter(String writerName) {
        return approvalRepository.countByStatusAndWriter(writerName).stream()
                .collect(Collectors.toMap(
                        StatusCount::getStatus,
                        sc -> sc.getCnt().intValue()
                ));
    }

    /**
     * 승인자/관리자용 전체 상태별 결재 건수 요약
     */
    public Map<String, Integer> getStatusSummaryForApprover() {
        return approvalRepository.countByStatus().stream()
                .collect(Collectors.toMap(
                        StatusCount::getStatus,
                        sc -> sc.getCnt().intValue()
                ));
    }

    /**
     * 작성자 기준 최근 반려 결재 목록 조회
     */
    public List<Approval> findRecentRejectedByWriter(String adminname, int limit) {
        Pageable pageable = PageRequest.of(
                0, limit, Sort.by(Sort.Direction.DESC, "regDate"));

        return approvalRepository
                .findByWriterAdminnameAndStatus(adminname, "반려", pageable)
                .getContent();
    }

    /**
     * 작성자 기준 평균 처리 일수 계산
     * 기준: 등록일 → 배포 시점
     */
    public double calculateAvgDaysByWriter(String adminname) {
        return approvalLogService.findAllByNewStatusAndWriter("배포", adminname).stream()
                .mapToLong(log ->
                        Duration.between(
                                log.getApproval().getRegDate(),
                                log.getChangedAt()
                        ).toDays()
                )
                .average()
                .orElse(0.0);
    }
}
