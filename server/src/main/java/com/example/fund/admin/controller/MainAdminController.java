package com.example.fund.admin.controller;

import java.io.IOException;
import java.util.List;

import com.example.fund.fund.entity_fund.FundDocument;
import com.example.fund.fund.repository_fund.FundDocumentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import com.example.fund.admin.dto.AdminDTO;
import com.example.fund.admin.entity.Admin;
import com.example.fund.admin.service.AdminService_A;
import com.example.fund.fund.dto.FundDetailResponse;
import com.example.fund.fund.service.FundService;
import com.example.fund.qna.service.QnaService;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import lombok.RequiredArgsConstructor;

@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class MainAdminController {

    // 펀드 문서 관련 Repository
    private final FundDocumentRepository fundDocumentRepository;

    // 관리자 관련 비즈니스 로직 Service
    private final AdminService_A adminService_a;

    // Q&A 관련 Service
    private final QnaService qnaService;

    // 펀드 관련 Service
    private final FundService fundService;


    /*
     * 1) /admin/ 또는 /admin
     * - 세션에 admin 정보가 있으면 대시보드로 이동
     * - 없으면 관리자 로그인 페이지 반환
     */
    @GetMapping({ "/", "" })
    public String root(HttpSession session) {
        return (session.getAttribute("admin") != null)
                ? "redirect:/admin/dashboard"
                : "admin/login";
    }

    /*
     * 2) /admin/main
     * - 과거에 사용하던 주소
     * - 접근 시 무조건 대시보드로 리다이렉트
     */
    @GetMapping("/main")
    public String legacyMain() {
        return "redirect:/admin/dashboard";
    }

    /*
     * 3) 관리자 로그인 처리
     * - 로그인 성공 시 세션에 admin 정보 저장
     * - 실패 시 로그인 페이지로 리다이렉트하며 에러 메시지 전달
     */
    @PostMapping("/login")
    public String login(
            AdminDTO adminDTO,                // 로그인 폼에서 전달된 관리자 정보
            HttpServletRequest request,       // 세션 접근을 위한 request 객체
            RedirectAttributes rttr            // 리다이렉트 시 메시지 전달용
    ) {

        // 로그인 실패 시
        if (!adminService_a.login(adminDTO)) {
            rttr.addFlashAttribute("msg", "아이디 또는 비밀번호를 확인하세요");
            return "redirect:/admin/";
        }

        // 로그인 성공 시 관리자 엔티티 조회
        Admin adminEntity = adminService_a.searchAdmin(adminDTO);

        // 세션에 저장할 DTO 객체 생성
        AdminDTO sess = new AdminDTO();
        sess.setRole(adminEntity.getRole());
        sess.setAdmin_id(adminEntity.getAdmin_id());
        sess.setName(adminEntity.getName());
        sess.setAdminname(adminEntity.getAdminname());

        // 세션에 관리자 정보 저장
        request.getSession().setAttribute("admin", sess);

        // 로그인 성공 후 관리자 대시보드로 이동
        return "redirect:/admin/dashboard";
    }

    /*
     * 관리자 로그아웃
     * - 세션에서 admin 정보 제거
     * - 로그아웃 메시지 전달 후 로그인 페이지로 이동
     */
    @GetMapping("/logout")
    public String logout(HttpServletRequest request, RedirectAttributes rttr) {
        request.getSession().removeAttribute("admin");
        rttr.addFlashAttribute("logoutMsg", "로그아웃");
        return "redirect:/admin/";
    }

    /*
     * 관리자 아이디(관리자명) 중복 체크
     * - AJAX 요청용
     * - true / false 반환
     */
    @GetMapping("/check-id")
    public ResponseEntity<Boolean> checkDuplicateAdminname(@RequestParam String adminname) {
        return ResponseEntity.ok(adminService_a.check_id(adminname));
    }

    /*
     * 관리자 등록 폼으로 이동 (슈퍼 관리자 전용)
     */
    @GetMapping("/adminRegistForm")
    public String adminRegistForm() {
        return "admin/super/admin_register";
    }

    /*
     * 관리자 설정 페이지 이동
     */
    @GetMapping("/adminSetting")
    public String adminSetting() {
        return "admin/super/adminSetting";
    }

    /*
     * 관리자 등록 처리
     * - 등록 완료 후 메시지 전달
     */
    @PostMapping("/adminRegist")
    public String adminRegist(
            AdminDTO adminDTO,
            RedirectAttributes rttr
    ) {
        adminService_a.adminRegist(adminDTO);
        rttr.addFlashAttribute("msg", "관리자 등록을 완료하였습니다");
        return "admin/super/adminSetting";
    }

    /*
     * 관리자 리스트 조회
     * - role 파라미터 선택값
     * - 페이지네이션 처리
     */
    @GetMapping("/list")
    public String getAdminList(
            @RequestParam(required = false) String role,  // 관리자 권한 필터
            @RequestParam(defaultValue = "0") int page,   // 페이지 번호
            @RequestParam(defaultValue = "10") int size,  // 페이지 크기
            Model model
    ) {
        Pageable pageable = PageRequest.of(page, size);

        // role 유무에 따라 전체 조회 또는 권한별 조회
        Page<AdminDTO> adminPage = (role == null || role.isEmpty())
                ? adminService_a.getAllAdmins(pageable)
                : adminService_a.getAdminsByRole(role, pageable);

        // 페이지 정보 및 리스트 전달
        model.addAttribute("adminPage", adminPage);
        model.addAttribute("adminList", adminPage.getContent());

        // Thymeleaf fragment 반환
        return "admin/super/adminList :: admin-list-content";
    }

    /*
     * 관리자 상세 정보 조회
     * - 관리자 수정 모달용
     */
    @GetMapping("/detail/{id}")
    public String getAdminDetail(
            @PathVariable Integer id,
            Model model
    ) {
        model.addAttribute("admin", adminService_a.findById(id));
        return "admin/super/adminList :: admin-modify-modal";
    }

    /*
     * 관리자 권한(role) 변경
     * - AJAX 요청 처리
     */
    @PostMapping("/updateRole")
    @ResponseBody
    public String updateRole(@RequestBody AdminDTO adminDTO) {
        adminService_a.updateRole(adminDTO.getAdmin_id(), adminDTO.getRole());
        return "success";
    }

    /*
     * 관리자 삭제
     * - AJAX 요청 처리
     */
    @DeleteMapping("/delete/{id}")
    @ResponseBody
    public String deleteAdmin(@PathVariable Integer id) {
        adminService_a.deleteAdmin(id);
        return "success";
    }

    /*
     * Q&A 관리 페이지 이동
     */
    @GetMapping("/qnaList")
    public String qnaList() {
        return "admin/cs/qnaSetting";
    }

    /*
     * 펀드 신규 등록 폼 이동
     */
    @GetMapping("/fund/new")
    public String newFundForm() {
        return "fund/fundRegister";
    }

    /*
     * 펀드 리스트 페이지
     * - 현재는 공사 중 페이지 반환
     */
    @GetMapping("/fund/list")
    public String fundListPage(
            @PageableDefault(size = 10) Pageable pageable,
            Model model
    ) {
        // 펀드 정책 리스트 조회 예정
        return "admin/constructionPage";
    }

    /*
     * 펀드 통계 페이지 (공사 페이지)
     */
    @GetMapping("/fund_statistics")
    public String construction() {
        return "admin/fund_statistics";
    }
}


//    @GetMapping("/fund/view/{id}")
//    public String viewFundDetail(@PathVariable Long id, Model model) {
//
//        Fund fund = fundService.findById(id)
//                .orElseThrow(() -> new NoSuchElementException("펀드를 찾을 수 없습니다. id=" + id));
//
//        FundPolicy policy = fundPolicyRepository.findByFund_FundId(id).orElse(null);
//
//        // 문서들 조회 (리포지토리 이름은 예시 – 실제 이름에 맞게 사용)
//        List<FundDocument> docs = fundDocumentRepository.findByFund_FundId(id);
//
//        Long termsFileId      = getDocId(docs, "약관");
//        Long manualFileId     = getDocId(docs, "상품설명서");
//        Long prospectusFileId = getDocId(docs, "투자설명서");
//
//        String termsFileName      = getDocName(docs, "약관");
//        String manualFileName     = getDocName(docs, "상품설명서");
//        String prospectusFileName = getDocName(docs, "투자설명서");
//
//        model.addAttribute("fund", fund);
//        model.addAttribute("policy", policy);
//        model.addAttribute("termsFileId", termsFileId);
//        model.addAttribute("manualFileId", manualFileId);
//        model.addAttribute("prospectusFileId", prospectusFileId);
//        model.addAttribute("termsFileName", termsFileName);
//        model.addAttribute("manualFileName", manualFileName);
//        model.addAttribute("prospectusFileName", prospectusFileName);
//
//        return "fund/fundRegistDetail";
//    }

    // 잠시 fundPolicy 주석
    /*
    @GetMapping("/fund/view/{id}")
    public String viewFundDetail(@PathVariable String id, Model model) {
        // FundDetailResponse fund = fundService.getFundDetailWithPolicy(id);

        // FundPolicy policy = fundPolicyRepository.findByFund_FundId(id).orElse(null);

        // model.addAttribute("fund", fund);
        // model.addAttribute("policy", policy);
        return "fund/fundRegistDetail";
    }
    */

//    // 수정하기 페이지로 이동
//    @GetMapping("/fund/edit/{id}")
//    public String editPage(@PathVariable("id") Long id,
//            @RequestParam(name = "includePolicy", defaultValue = "false") boolean includePolicy,
//            Model model) {
//        FundDetailResponse fund = includePolicy
//                ? fundService.getFundDetailWithPolicy(id)
//                : fundService.getFundDetailBasic(id);
//
//        model.addAttribute("fund", fund);
//        return "fund/fundRegistEdit";
//    }

//    // 수정 폼 위 메서드를 수정
//    @GetMapping("/fund/edit/{id}")
//    public String editFund(@PathVariable Long id, Model model) {
//        FundDetailResponse fund = fundService.getFundDetailWithPolicy(id);
//        model.addAttribute("fund", fund);
//        return "fund/fundRegistEdit";
//    }


    // 잠시 fundPolicy 주석
    /*
    @GetMapping("/fund/edit/{id}")
    public String editPage(@PathVariable("id") Long id, Model model) {
        // 정책까지 꼭 포함된 DTO 를 가져오도록 강제
        // FundDetailResponse fund = fundService.getFundDetailWithPolicy(id);
        // model.addAttribute("fund", fund);
        return "fund/fundRegistEdit";
    }
    */


    /*
    private Long getDocId(List<FundDocument> list, String type){
        return list.stream()
                .filter(d -> type.equals(d.getDocType()))
                .map(FundDocument::getDocumentId)
                .findFirst().orElse(null);
    }
    */


    /*
    private String getDocName(List<FundDocument> list, String type){
        return list.stream()
                .filter(d -> type.equals(d.getDocType()))
                .map(FundDocument::getDocTitle)
                .findFirst().orElse(null);
    }
    */


    /*
    @PostMapping("/fund/update/{id}")
    public String updateFund(
            @PathVariable String id,
            @RequestParam String fundTheme,
            @RequestParam(required = false) MultipartFile fileTerms,
            @RequestParam(required = false) MultipartFile fileManual,
            @RequestParam(required = false) MultipartFile fileProspectus,
            RedirectAttributes rttr
    ) throws IOException {

        fundService.updateFundAdmin(id, fundTheme, fileTerms, fileManual, fileProspectus);

        rttr.addFlashAttribute("msg", "펀드 수정이 완료되었습니다.");
        return "redirect:/admin/fund/view/" + id;
    }
    */
