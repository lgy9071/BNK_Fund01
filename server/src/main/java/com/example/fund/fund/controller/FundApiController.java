package com.example.fund.fund.controller;

import com.example.fund.common.CurrentUid;
import com.example.fund.common.dto.ApiResponse;
import com.example.fund.fund.dto.FundDetailResponseDTO;
import com.example.fund.fund.dto.FundListResponseDTO;
import com.example.fund.fund.dto.InvestTypeResponse;
import com.example.fund.fund.entity_fund_etc.InvestProfileResult;
import com.example.fund.fund.repository_fund.FundDocumentRepository;
import com.example.fund.fund.repository_fund.FundRepository;
import com.example.fund.fund.repository_fund_etc.InvestProfileResultRepository;
import com.example.fund.fund.service.FundDetailService;
import com.example.fund.fund.service.FundQueryService;
import com.example.fund.fund.service.FundService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@Slf4j
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/funds")
@CrossOrigin(origins = "*")
public class FundApiController {

    private final FundService fundService;
    private final InvestProfileResultRepository investProfileResultRepository;
    private final FundRepository fundRepository;
    private final FundDocumentRepository fundDocumentRepository;
    private static final int MIN_INVEST_TYPE = 1;
    private static final int MAX_INVEST_TYPE = 5;

    private final FundQueryService fundQueryService;
    private final FundDetailService fundDetailService;

    /**
     * 펀드 목록 조회
     * eligibleOnly=true -> 내 투자성향 이하 상품만 필터링
     */
    @GetMapping
    public ResponseEntity<ApiResponse<List<FundListResponseDTO>>> list(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "false") boolean eligibleOnly,
            @CurrentUid Integer uid
    ) {
        ApiResponse<List<FundListResponseDTO>> body = fundQueryService.getFundsEligible(keyword, page, size, uid);
        return ResponseEntity.ok(body);
    }

    @GetMapping("/{fundId}")
    public ResponseEntity<ApiResponse<FundDetailResponseDTO>> detail(@PathVariable String fundId) {
        ApiResponse<FundDetailResponseDTO> body = fundDetailService.getFundDetail(fundId);
        return ResponseEntity.ok(body);
    }

    /** 투자 성향에 따른 펀드 목록 - REST API */
    /*
     * {
     * "success": true,
     * "data": [...],
     * "investType": 3,
     * "investTypeName": "위험 중립형",
     * "pagination": {
     * "page": 1,
     * "limit": 10,
     * "total": 50,
     * "totalPages": 5,
     * "hasNext": true,
     * "hasPrev": false,
     * "currentItems": 10
     * }
     * }
     */
    /*
     * @GetMapping("/list")
     * public ResponseEntity<ApiResponse<FundListResponse>> getFundList(
     *
     * @RequestParam(defaultValue = "1") int page,
     *
     * @RequestParam(defaultValue = "10") int size,
     *
     * @RequestParam Integer investType,
     *
     * @RequestParam(required = false) List<String> risk, // 위험등급 필터
     *
     * @RequestParam(required = false) List<String> type, // 펀드유형 필터
     *
     * @RequestParam(required = false) List<String> region // 투자지역 필터
     * ) {
     * try {
     * // 1. 투자성향 유효성 검사
     * if (investType < MIN_INVEST_TYPE || investType > MAX_INVEST_TYPE) {
     * return ResponseEntity.badRequest()
     * .body(ApiResponse.failure(
     * "투자 성향은 1~5 사이의 값이어야 합니다.",
     * "INVALID_INVESTMENT_TYPE"
     * ));
     * }
     *
     * // 2. 페이지네이션 설정 (0-based indexing)
     * Pageable pageable = PageRequest.of(page - 1, size,
     * Sort.by("fundId").descending());
     *
     * // 3. 필터 조건 로깅 (디버깅용)
     * log.
     * info("펀드 목록 조회 요청 - investType: {}, risk: {}, type: {}, region: {}, page: {}"
     * ,
     * investType, risk, type, region, page);
     *
     * // 4. 펀드 데이터 조회 - 필터 조건이 있으면 필터링, 없으면 기본 조회
     * Page<FundPolicyResponseDTO> fundPage;
     *
     * boolean hasFilters = (risk != null && !risk.isEmpty()) ||
     * (type != null && !type.isEmpty()) ||
     * (region != null && !region.isEmpty());
     *
     * if (hasFilters) {
     * // 필터 조건이 있는 경우 - 새로운 메서드 사용
     * log.info("필터링 조건 적용하여 펀드 조회");
     * fundPage = fundService.findWithFilters(investType, risk, type, region,
     * pageable);
     * } else {
     * // 필터 조건이 없는 경우 - 기존 메서드 사용
     * log.info("투자성향만으로 펀드 조회");
     * fundPage = fundService.findByInvestType(investType, pageable);
     * }
     *
     * // 5. 투자성향 이름 조회
     * String investTypeName = getInvestTypeName(investType);
     *
     * // 6. 응답 데이터 구성
     * FundListResponse fundListResponse = FundListResponse.builder()
     * .funds(fundPage.getContent())
     * .investType(investType)
     * .investTypeName(investTypeName)
     * .build();
     *
     * // 7. 페이지네이션 정보 생성
     * PaginationInfo paginationInfo = PaginationInfo.from(fundPage, page);
     *
     * // 8. 성공 응답 로깅
     * log.info("펀드 목록 조회 성공: investType={}, 필터적용={}, totalElements={}",
     * investType, hasFilters, fundPage.getTotalElements());
     *
     * // 9. 성공 응답 반환
     * String responseMessage = hasFilters
     * ? String.format("%s 조건으로 필터링된 펀드 %d개를 조회했습니다.", investTypeName,
     * fundPage.getNumberOfElements())
     * : String.format("%s에 맞는 펀드 %d개를 조회했습니다.", investTypeName,
     * fundPage.getNumberOfElements());
     *
     * return ResponseEntity.ok(
     * ApiResponse.success(
     * fundListResponse,
     * responseMessage,
     * paginationInfo
     * )
     * );
     *
     * } catch (IllegalArgumentException e) {
     * log.warn("잘못된 파라미터: investType={}, error={}", investType, e.getMessage());
     * return ResponseEntity.badRequest()
     * .body(ApiResponse.failure(e.getMessage(), "INVALID_PARAMETER"));
     *
     * } catch (Exception e) {
     * log.
     * error("펀드 목록 조회 중 오류 발생: investType={}, filters=[risk:{}, type:{}, region:{}]"
     * ,
     * investType, risk, type, region, e);
     * return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
     * .body(ApiResponse.failure(
     * "서버 오류가 발생했습니다.",
     * "INTERNAL_SERVER_ERROR"
     * ));
     * }
     * }
     */

    /** 펀드 상세 정보 제공 - REST API */
    /*
     * @GetMapping("/detail/{fundId}")
     * public ResponseEntity<ApiResponse<?>> getFund(
     *
     * @PathVariable("fundId") String fundId,
     *
     * @RequestParam(required = false) Integer investType // 현재 사용 안함
     * ) {
     * try {
     * // 투자성향 확인
     * // Integer userId = user.getUserId();
     * // Optional<InvestProfileResult> investResult =
     * investProfileResultRepository.findByUser_UserId(userId);
     * // if (!investResult.isPresent()) {
     * // log.warn("투자 성향 미설정 사용자의 펀드 상세 API 호출 - userId: {}, fundId: {}", userId,
     * fundId);
     * // return ResponseEntity.status(HttpStatus.PRECONDITION_REQUIRED)
     * // .body(ApiResponseDto.failure("투자 성향 검사가 필요합니다.",
     * "INVEST_PROFILE_REQUIRED"));
     * // }
     *
     * // Integer investType = investResult.get().getType().getTypeId().intValue();
     * // og.debug("사용자 투자성향 확인 - userId: {}, investType: {}", userId, investType);
     *
     * // 3. 펀드 상세 정보 조회
     * FundDetailResponseDTO fundDetail = fundService.getFundDetail(fundId);
     *
     * // 4. 펀드 존재 여부 확인
     * if (fundDetail == null) {
     * log.warn("존재하지 않는 펀드 조회 - fundId: {}", fundId);
     * return ResponseEntity.status(HttpStatus.NOT_FOUND)
     * .body(ApiResponse.failure("존재하지 않는 펀드입니다.", "FUND_NOT_FOUND"));
     * }
     *
     * // 5. 정상 응답
     * log.info("펀드 상세 정보 API 성공 - fundId: {}", fundId);
     * return ResponseEntity.ok(ApiResponse.success(fundDetail, "펀드 상세 정보 조회 성공"));
     *
     * } catch (Exception e) {
     * log.error("펀드 상세 정보 API 오류 - fundId: {}", fundId, e);
     * return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
     * .body(ApiResponse.failure("서버 오류가 발생했습니다.", "INTERNAL_ERROR"));
     * }
     * }
     */

    /**
     * 사용자 투자성향 조회 API
     */
    /*
     * // 투자성향이 있는 경우
     * {
     * "success": true,
     * "hasProfile": true,
     * "investType": 3,
     * "investTypeName": "위험 중립형",
     * "message": "투자 성향을 성공적으로 조회했습니다."
     * }
     *
     * // 투자성향이 없는 경우
     * {
     * "success": true,
     * "hasProfile": false,
     * "message": "투자 성향 검사가 필요합니다.",
     * "investType": null
     * }
     */
    @GetMapping("/invest-type")
    public ResponseEntity<ApiResponse<InvestTypeResponse>> getUserInvestType(@RequestParam Integer userId) {
        try {
            // 사용자 투자성향 조회
            Optional<InvestProfileResult> investResult = investProfileResultRepository.findByUser_UserId(userId);

            if (investResult.isEmpty()) {
                InvestTypeResponse response = InvestTypeResponse.builder()
                        .hasProfile(false)
                        .investType(null)
                        .investTypeName(null)
                        .build();

                return ResponseEntity.ok(
                        ApiResponse.success(response, "투자 성향 검사가 필요합니다."));
            }

            InvestProfileResult result = investResult.get();
            Integer investType = result.getType().getTypeId().intValue();
            String investTypeName = getInvestTypeName(investType);

            InvestTypeResponse response = InvestTypeResponse.builder()
                    .hasProfile(true)
                    .investType(investType)
                    .investTypeName(investTypeName)
                    .build();

            log.info("투자 성향 조회 성공: userId={}, investType={}", userId, investType);
            return ResponseEntity.ok(
                    ApiResponse.success(response, "투자 성향을 성공적으로 조회했습니다."));

        } catch (Exception e) {
            log.error("투자성향 조회 중 오류 발생: userId={}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.failure(
                            "투자 성향 조회 중 오류가 발생했습니다.",
                            "INTERNAL_SERVER_ERROR"));
        }
    }

    /**
     * 투자성향 이름 반환
     */
    private String getInvestTypeName(int investType) {
        return switch (investType) {
            case 1 -> "안정형";
            case 2 -> "안정 추구형";
            case 3 -> "위험 중립형";
            case 4 -> "적극 투자형";
            case 5 -> "공격 투자형";
            default -> "알 수 없음";
        };
    }

    // ====================================================================================================

    /* 펀드 이름으로 검색 API */
    /*
     * @GetMapping("/search")
     * public ResponseEntity<List<Map<String, Object>>>
     * searchFund(@RequestParam("name") String name) {
     * List<Fund> funds = fundRepository.findByFundNameContainingIgnoreCase(name);
     *
     * List<Map<String, Object>> result = funds.stream().map(f -> {
     * Map<String, Object> map = new HashMap<>();
     * map.put("fundId", f.getFundId());
     * map.put("fundName", f.getFundName());
     * return map;
     * }).collect(Collectors.toList());
     *
     * return ResponseEntity.ok(result);
     * }
     */

    /** 배포로 등록된 데이터 List만 보여주는 api */
    /*
     * @GetMapping("/search/available")
     * public ResponseEntity<List<Fund>> getFundsWithoutPolicy() {
     * List<Fund> result = fundRepository.findFundsNotInFundPolicy();
     * return ResponseEntity.ok(result);
     * }
     */

    /* 공시파일 다운로드 */
    /*
     * @GetMapping("/files/document/{id}")
     * public ResponseEntity<org.springframework.core.io.Resource>
     * downloadFundDocument(@PathVariable("id") Long id) {
     * FundDocument document = fundDocumentRepository.findById(id)
     * .orElseThrow(() -> new RuntimeException("문서를 찾을 수 없습니다."));
     *
     * Path path = Paths.get(document.getFilePath());
     * org.springframework.core.io.Resource resource;
     *
     * try {
     * resource = new UrlResource(path.toUri());
     * } catch (MalformedURLException e) {
     * throw new RuntimeException("파일 경로가 잘못되었습니다.", e);
     * }
     *
     * if (!resource.exists() || !resource.isReadable()) {
     * throw new RuntimeException("파일을 읽을 수 없습니다.");
     * }
     *
     * // 파일명 인코딩 (한글 파일 대응)
     * String encodedFileName;
     * try {
     * encodedFileName = java.net.URLEncoder.encode(document.getDocTitle() + ".pdf",
     * "UTF-8")
     * .replaceAll("\\+", "%20");
     * } catch (Exception e) {
     * encodedFileName = "document.pdf";
     * }
     *
     * return ResponseEntity.ok()
     * .header(org.springframework.http.HttpHeaders.CONTENT_DISPOSITION,
     * "attachment; filename=\"" + encodedFileName + "\"")
     * .contentType(MediaType.APPLICATION_PDF)
     * .body(resource);
     * }
     */

    /**
     * 펀드 상세 데이터 조회 - REST API - ?
     */
    /*
     * @GetMapping("/{fundId}")
     * public ResponseEntity<?> getFundDetail(
     *
     * @PathVariable("fundId") Long fundId,
     *
     * @RequestParam(name = "includePolicy", defaultValue = "false") boolean
     * includePolicy
     * ) {
     * try {
     * if (includePolicy) {
     * FundDetailResponse response = fundService.getFundDetailWithPolicy(fundId);
     * return ResponseEntity.ok(response);
     * } else {
     * FundDetailResponse response = fundService.getFundDetailBasic(fundId);
     * return ResponseEntity.ok(response);
     * }
     * } catch (Exception e) {
     * e.printStackTrace(); // 간단한 로그
     * return ResponseEntity.notFound().build();
     * }
     * }
     */

}
