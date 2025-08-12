package com.example.ap.service.fund;

import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import javax.imageio.ImageIO;

import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.example.ap.repository.fund.FundDocumentRepository;
import com.example.ap.repository.fund.FundPolicyRepository;
import com.example.ap.repository.fund.FundPortfolioRepository;
import com.example.ap.repository.fund.FundRepository;
import com.example.ap.repository.fund.FundReturnRepository;
import com.example.common.dto.fund.FundDetailResponse;
import com.example.common.dto.fund.FundDetailResponseDTO;
import com.example.common.dto.fund.FundPolicyResponseDTO;
import com.example.common.dto.fund.FundRegisterRequest;
import com.example.common.entity.fund.Fund;
import com.example.common.entity.fund.FundDocument;
import com.example.common.entity.fund.FundPolicy;
import com.example.common.entity.fund.FundPortfolio;
import com.example.common.entity.fund.FundReturn;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class FundService {

    private final FundRepository fundRepository;
    private final FundReturnRepository fundReturnRepository;
    private final FundPortfolioRepository fundPortfolioRepository;
    private final FundPolicyRepository fundPolicyRepository;
    private final FundDocumentRepository fundDocumentRepository;

    /**
     * 새로운 메서드 - 투자 성향 + 필터링 조건을 모두 적용한 펀드 목록 조회
     */
    public FundDetailResponse getFundDetailBasic(Long fundId) {
        Fund fund = fundRepository.findByFundId(fundId)
                .orElseThrow(() -> new RuntimeException("펀드를 찾을 수 없습니다."));

        List<FundDocument> documents = fundDocumentRepository.findByFund_FundId(fundId);

        Long termsFileId = null;
        Long manualFileId = null;
        Long prospectusFileId = null;
        String termsFileName = null;
        String manualFileName = null;
        String prospectusFileName = null;

        for (FundDocument doc : documents) {
            switch (doc.getDocType()) {
                case "약관" -> {
                    termsFileId = doc.getDocumentId();
                    termsFileName = doc.getDocTitle();
                }
                case "상품설명서" -> {
                    manualFileId = doc.getDocumentId();
                    manualFileName = doc.getDocTitle();
                }
                case "투자설명서" -> {
                    prospectusFileId = doc.getDocumentId();
                    prospectusFileName = doc.getDocTitle();
                }
            }
        }

        return FundDetailResponse.builder()
                .fundId(fund.getFundId())
                .fundName(fund.getFundName())
                .fundTheme(null) // 정책 없음
                .fundType(fund.getFundType())
                .investmentRegion(fund.getInvestmentRegion())
                .establishDate(fund.getEstablishDate())
                .managementCompany(fund.getManagementCompany())
                .riskLevel(fund.getRiskLevel())
                .totalExpenseRatio(fund.getTotalExpenseRatio())
                .termsFileId(termsFileId)
                .manualFileId(manualFileId)
                .prospectusFileId(prospectusFileId)
                .termsFileName(termsFileName)
                .manualFileName(manualFileName)
                .prospectusFileName(prospectusFileName)
                .build();
    }

    /**
     * 펀드 상세 정보 조회 (정책 포함)
     */
    public FundDetailResponse getFundDetailWithPolicy(Long fundId) {
        Fund fund = fundRepository.findByFundId(fundId)
                .orElseThrow(() -> new RuntimeException("펀드를 찾을 수 없습니다."));

        FundPolicy policy = fundPolicyRepository.findByFund_FundId(fundId)
                .orElseThrow(() -> new RuntimeException("펀드 정책을 찾을 수 없습니다."));

        List<FundDocument> documents = fundDocumentRepository.findByFund_FundId(fundId);

        Long termsFileId = null;
        Long manualFileId = null;
        Long prospectusFileId = null;
        String termsFileName = null;
        String manualFileName = null;
        String prospectusFileName = null;

        for (FundDocument doc : documents) {
            switch (doc.getDocType()) {
                case "약관" -> {
                    termsFileId = doc.getDocumentId();
                    termsFileName = doc.getDocTitle();
                }
                case "상품설명서" -> {
                    manualFileId = doc.getDocumentId();
                    manualFileName = doc.getDocTitle();
                }
                case "투자설명서" -> {
                    prospectusFileId = doc.getDocumentId();
                    prospectusFileName = doc.getDocTitle();
                }
            }
        }


        return FundDetailResponse.builder()
                .fundId(fund.getFundId())
                .fundName(fund.getFundName())
                .fundTheme(policy.getFundTheme())
                .fundType(fund.getFundType())
                .investmentRegion(fund.getInvestmentRegion())
                .establishDate(fund.getEstablishDate())
                .managementCompany(fund.getManagementCompany())
                .riskLevel(fund.getRiskLevel())
                .totalExpenseRatio(fund.getTotalExpenseRatio())
                .termsFileId(termsFileId)
                .manualFileId(manualFileId)
                .prospectusFileId(prospectusFileId)
                .termsFileName(termsFileName)
                .manualFileName(manualFileName)
                .prospectusFileName(prospectusFileName)
                .build();
    }

    /**
     * 모든 펀드 목록 조회
     */
    public List<Fund> findAll() {
        return fundRepository.findAll();
    }

    public List<Fund> getAllFunds() {
        return fundRepository.findAll();
    }

    /**
     * 특정 펀드 ID 조회
     */
    public Optional<Fund> findById(Long id) {
        return fundRepository.findById(id);
    }

    /**
     * 펀드 등록
     */
    public Fund save(Fund fund) {
        return fundRepository.save(fund);
    }

    /**
     * 펀드 정보 수정
     */
    public Fund update(Long id, Fund updatedFund) {
        return fundRepository.findById(id)
                .map(fund -> {
                    fund.setFundName(updatedFund.getFundName());
                    fund.setFundType(updatedFund.getFundType());
                    fund.setInvestmentRegion(updatedFund.getInvestmentRegion());
                    fund.setEstablishDate(updatedFund.getEstablishDate());
                    fund.setLaunchDate(updatedFund.getLaunchDate());
                    fund.setNav(updatedFund.getNav());
                    fund.setAum(updatedFund.getAum());
                    fund.setTotalExpenseRatio(updatedFund.getTotalExpenseRatio());
                    fund.setRiskLevel(updatedFund.getRiskLevel());
                    fund.setManagementCompany(updatedFund.getManagementCompany());
                    return fundRepository.save(fund);
                }).orElseThrow(() -> new RuntimeException("Fund not found"));
    }

    /**
     * 특정 펀드 삭제
     */
    public void delete(Long id) {
        fundRepository.deleteById(id);
    }

    /*PDF 저장 & JPG 변환*/
    private final String UPLOAD_DIR = "C:\\bnk_project\\data\\uploads\\fund_document\\";

    @Transactional
    public Long registerFundWithAllDocuments(
            FundRegisterRequest request,
            MultipartFile fileTerms,
            MultipartFile fileManual,
            MultipartFile fileProspectus
    ) throws IOException {
        Fund fund = fundRepository.findByFundId(request.getFundId())
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펀드 ID"));

        // 정책 저장
        FundPolicy policy = FundPolicy.builder()
                .fund(fund)
                .fundTheme(request.getFundTheme())
                .fundActive(request.getFundActive())
                .fundRelease(request.getFundRelease())
                .build();
        fundPolicyRepository.save(policy);

        // 문서 저장
        saveFundDocument(fund, fileTerms, "약관");
        saveFundDocument(fund, fileManual, "상품설명서");
        saveFundDocument(fund, fileProspectus, "투자설명서");

        // 등록된 펀드 ID 반환
        return fund.getFundId();
    }


    private void saveFundDocument(Fund fund, MultipartFile file, String docType) throws IOException {
        String today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String generatedDocTitle = fund.getFundName() + "_" + docType + "_" + today;
        String filePath = savePdfAndConvertToJpg(file, "fund_doc", generatedDocTitle);

        FundDocument doc = FundDocument.builder()
                .fund(fund)
                .docType(docType)
                .docTitle(generatedDocTitle)
                .filePath(filePath)
                .fileFormat("PDF")
                .uploadedAt(LocalDate.now())
                .build();

        fundDocumentRepository.save(doc);
    }

    private String savePdfAndConvertToJpg(MultipartFile file, String fileType, String filename) throws IOException {
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !originalFilename.toLowerCase().endsWith(".pdf")) {
            throw new IOException("Only PDF files are allowed.");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.equals("application/pdf")) {
            throw new IOException("Invalid file type.");
        }

        String dateFolder = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String storedFilename = filename;

        Path dirPath = Paths.get(UPLOAD_DIR, fileType, dateFolder);
        Files.createDirectories(dirPath);

        Path pdfPath = dirPath.resolve(storedFilename + ".pdf");
        Files.copy(file.getInputStream(), pdfPath, StandardCopyOption.REPLACE_EXISTING);

        try (PDDocument document = PDDocument.load(pdfPath.toFile())) {
            PDFRenderer renderer = new PDFRenderer(document);
            for (int i = 0; i < document.getNumberOfPages(); i++) {
                BufferedImage image = renderer.renderImageWithDPI(i, 125);
                String jpgName = String.format("%s_%d.jpg", storedFilename, i + 1);
                Path jpgPath = dirPath.resolve(jpgName);
                ImageIO.write(image, "jpg", jpgPath.toFile());
            }
        }

        return pdfPath.toString(); // DB에는 PDF 경로 저장
    }


    // ============================================================================================================

    /**
     * 투자 성향 + 3개월 수익률 중에세 가장 높은 수익률 10개를 조회
     */
    public List<FundPolicyResponseDTO> findBestReturn(
            Integer investType,
            Pageable pageable
    ) {
        // 투자 성향 → 위험 등급 범위 계산 (기본 필터)
        int startRiskLevel;
        int endRiskLevel = 6;
        switch (investType) {
            case 1 -> startRiskLevel = 6; // 안정형: 6등급만
            case 2 -> startRiskLevel = 5; // 안정 추구형: 5~6등급
            case 3 -> startRiskLevel = 4; // 위험 중립형: 4~6등급
            case 4 -> startRiskLevel = 3; // 적극 투자형: 3~6등급
            case 5 -> startRiskLevel = 1; // 공격 투자형: 1~6등급
            default -> throw new IllegalArgumentException("올바르지 않은 투자 성향입니다.");
        }

        List<Fund> fundList = fundRepository.findTopFundsByRiskLevelAndReturn3m(startRiskLevel, endRiskLevel, pageable);
        return convertToFundResponseDTO(fundList);
    }

    /**
     * 투자 성향 + 필터링 조건을 모두 적용한 펀드 목록 조회
     *
     * @param investType 투자성향 (1~5)
     * @param riskLevels 사용자가 선택한 위험등급 리스트 (선택사항)
     * @param fundTypes  사용자가 선택한 펀드유형 리스트 (선택사항)
     * @param regions    사용자가 선택한 투자지역 리스트 (선택사항)
     * @param pageable   페이지네이션 정보
     * @param fundTypes  사용자가 선택한 펀드유형 리스트 (선택사항)
     * @param regions    사용자가 선택한 투자지역 리스트 (선택사항)
     * @param pageable   페이지네이션 정보
     * @return 조건에 맞는 펀드 페이지
     */
    public Page<FundPolicyResponseDTO> findWithFilters(
            Integer investType,
            List<String> riskLevels,
            List<String> fundTypes,
            List<String> regions,
            Pageable pageable
    ) {
        // 1. 투자 성향 → 위험 등급 범위 계산 (기본 필터)
        int startRiskLevel;
        int endRiskLevel = 6;

        switch (investType) {
            case 1 -> startRiskLevel = 6; // 안정형: 6등급만
            case 2 -> startRiskLevel = 5; // 안정 추구형: 5~6등급
            case 3 -> startRiskLevel = 4; // 위험 중립형: 4~6등급
            case 4 -> startRiskLevel = 3; // 적극 투자형: 3~6등급
            case 5 -> startRiskLevel = 1; // 공격 투자형: 1~6등급
            default -> throw new IllegalArgumentException("올바르지 않은 투자 성향입니다.");
        }

        // 2. 문자열 리스트를 적절한 타입으로 변환
        List<Integer> riskLevelInts = convertToIntegerList(riskLevels);
        List<String> processedFundTypes = processEmptyList(fundTypes);
        List<String> processedRegions = processEmptyList(regions);

        log.info("필터링 조건 - investType: {}, riskLevels: {}, fundTypes: {}, regions: {}",
                investType, riskLevelInts, processedFundTypes, processedRegions);

        // 3. Repository에서 필터링된 데이터 조회
        Page<Fund> fundPage = fundRepository.findWithFilters(
                startRiskLevel,
                endRiskLevel,
                riskLevelInts,
                processedFundTypes,
                processedRegions,
                pageable
        );

        // 4. Entity → DTO 변환
        return convertToFundResponseDTO(fundPage);
    }

    public Page<FundPolicyResponseDTO> findWithFilters_policy(
            Integer investType,
            List<String> riskLevels,
            List<String> fundTypes,
            List<String> regions,
            Pageable pageable
    ) {
        // 1. 투자 성향 → 위험 등급 범위 계산 (기본 필터)
        int startRiskLevel;
        int endRiskLevel = 6;

        switch (investType) {
            case 1 -> startRiskLevel = 6; // 안정형: 6등급만
            case 2 -> startRiskLevel = 5; // 안정 추구형: 5~6등급
            case 3 -> startRiskLevel = 4; // 위험 중립형: 4~6등급
            case 4 -> startRiskLevel = 3; // 적극 투자형: 3~6등급
            case 5 -> startRiskLevel = 1; // 공격 투자형: 1~6등급
            default -> throw new IllegalArgumentException("올바르지 않은 투자 성향입니다.");
        }

        // 2. 문자열 리스트를 적절한 타입으로 변환
        List<Integer> riskLevelInts = convertToIntegerList(riskLevels);
        List<String> processedFundTypes = processEmptyList(fundTypes);
        List<String> processedRegions = processEmptyList(regions);

        // 3. FundPolicy에서 isActive=true인 데이터만 필터링하여 조회
        Page<FundPolicy> fundPolicyPage = fundPolicyRepository.findActiveFundPoliciesWithFilters(
                startRiskLevel,
                endRiskLevel,
                riskLevelInts,
                processedFundTypes,
                processedRegions,
                pageable
        );

        // 4. FundPolicy → FundResponseDTO 변환 (fundRelease를 launchDate로 사용)
        return convertFundPolicyToFundResponseDTO(fundPolicyPage);
    }


    /**
     * 투자 성향에 따른 펀드 목록 조회 - pagination
     */
    public Page<FundPolicyResponseDTO> findByInvestType(
            Integer investType,
            Pageable pageable
    ) {
        // 투자 성향 → 위험 등급 범위 계산
        int startRiskLevel;
        int endRiskLevel = 6;
        // String investTypeName = "";

        switch (investType) {
            case 1 -> startRiskLevel = 6; // 안정형
            case 2 -> startRiskLevel = 5; // 안정 추구형
            case 3 -> startRiskLevel = 4; // 위험 중립형
            case 4 -> startRiskLevel = 3; // 적극 투자형
            case 5 -> startRiskLevel = 1; // 공격 투자형
            default -> throw new IllegalArgumentException("올바르지 않은 투자 성향입니다.");
        }

        Page<Fund> fundPage = fundRepository.findByRiskLevelBetween(startRiskLevel, endRiskLevel, pageable);

        // ✅ fundPage → fundResponsePage 변환
        Page<FundPolicyResponseDTO> fundResponsePage = fundPage.map(fund -> {
            FundReturn fundReturn = fundReturnRepository.findByFund_FundId(fund.getFundId());

            return FundPolicyResponseDTO.builder()
                    .fundId(fund.getFundId())
                    .fundName(fund.getFundName())
                    .fundType(fund.getFundType())
                    .investmentRegion(fund.getInvestmentRegion())
                    .establishDate(fund.getEstablishDate())
                    .launchDate(fund.getLaunchDate())
                    .nav(fund.getNav())
                    .aum(fund.getAum())
                    .totalExpenseRatio(fund.getTotalExpenseRatio())
                    .riskLevel(fund.getRiskLevel())
                    .managementCompany(fund.getManagementCompany())
                    .return1m(fundReturn.getReturn1m())
                    .return3m(fundReturn.getReturn3m())
                    .return6m(fundReturn.getReturn6m())
                    .return12m(fundReturn.getReturn12m())
                    .returnSince(fundReturn.getReturnSince())
                    .build();
        });

        return fundResponsePage;
    }

    /**
     * Page<Fund>를 Page<FundResponseDTO>로 변환하는 메서드
     */
    private Page<FundPolicyResponseDTO> convertToFundResponseDTO(
            Page<Fund> fundPage
    ) {
        return fundPage.map(fund -> {
            // 각 펀드의 수익률 정보 조회
            FundReturn fundReturn = fundReturnRepository.findByFund_FundId(fund.getFundId());

            return FundPolicyResponseDTO.builder()
                    .fundId(fund.getFundId())
                    .fundName(fund.getFundName())
                    .fundType(fund.getFundType())
                    .investmentRegion(fund.getInvestmentRegion())
                    .establishDate(fund.getEstablishDate())
                    .launchDate(fund.getLaunchDate())
                    .nav(fund.getNav())
                    .aum(fund.getAum())
                    .totalExpenseRatio(fund.getTotalExpenseRatio())
                    .riskLevel(fund.getRiskLevel())
                    .managementCompany(fund.getManagementCompany())
                    .return1m(fundReturn != null ? fundReturn.getReturn1m() : null)
                    .return3m(fundReturn != null ? fundReturn.getReturn3m() : null)
                    .return6m(fundReturn != null ? fundReturn.getReturn6m() : null)
                    .return12m(fundReturn != null ? fundReturn.getReturn12m() : null)
                    .returnSince(fundReturn != null ? fundReturn.getReturnSince() : null)
                    .build();
        });
    }

    /**
     * List<Fund>를 List<FundResponseDTO>로 변환하는 메서드
     */
    private List<FundPolicyResponseDTO> convertToFundResponseDTO(
            List<Fund> fundList
    ) {
        return fundList.stream()
                .map(fund -> {
                    // 각 펀드의 수익률 정보 조회
                    FundReturn fundReturn = fundReturnRepository.findByFund_FundId(fund.getFundId());

                    return FundPolicyResponseDTO.builder()
                            .fundId(fund.getFundId())
                            .fundName(fund.getFundName())
                            .fundType(fund.getFundType())
                            .investmentRegion(fund.getInvestmentRegion())
                            .establishDate(fund.getEstablishDate())
                            .launchDate(fund.getLaunchDate())
                            .nav(fund.getNav())
                            .aum(fund.getAum())
                            .totalExpenseRatio(fund.getTotalExpenseRatio())
                            .riskLevel(fund.getRiskLevel())
                            .managementCompany(fund.getManagementCompany())
                            .return1m(fundReturn != null ? fundReturn.getReturn1m() : null)
                            .return3m(fundReturn != null ? fundReturn.getReturn3m() : null)
                            .return6m(fundReturn != null ? fundReturn.getReturn6m() : null)
                            .return12m(fundReturn != null ? fundReturn.getReturn12m() : null)
                            .returnSince(fundReturn != null ? fundReturn.getReturnSince() : null)
                            .build();
                })
                .collect(Collectors.toList());
    }

    /**
     * FundPolicy 페이지를 FundResponseDTO 페이지로 변환
     * N+1 문제를 해결하기 위해 배치로 FundReturn 조회
     */
    private Page<FundPolicyResponseDTO> convertFundPolicyToFundResponseDTO(Page<FundPolicy> fundPolicyPage) {
        // 1. 모든 fundId 수집
        List<Long> fundIds = fundPolicyPage.getContent()
                .stream()
                .map(fp -> fp.getFund().getFundId())
                .collect(Collectors.toList());

        // 2. 배치로 FundReturn 조회하여 Map으로 변환 (N+1 해결)
        Map<Long, FundReturn> fundReturnMap = new HashMap<>();
        if (!fundIds.isEmpty()) {
            List<FundReturn> fundReturns = fundReturnRepository.findByFund_FundIdIn(fundIds);
            fundReturnMap = fundReturns.stream()
                    .collect(Collectors.toMap(
                            fr -> fr.getFund().getFundId(),
                            fr -> fr,
                            (existing, replacement) -> existing // 중복 키 처리
                    ));
        }

        // 3. FundPolicy -> FundResponseDTO로 변환
        final Map<Long, FundReturn> finalFundReturnMap = fundReturnMap;

        return fundPolicyPage.map(fundPolicy -> {
            Fund fund = fundPolicy.getFund();
            FundReturn fundReturn = finalFundReturnMap.get(fund.getFundId());

            return FundPolicyResponseDTO.builder()
                    .fundId(fund.getFundId())
                    .fundName(fund.getFundName())
                    .fundType(fund.getFundType())
                    .investmentRegion(fund.getInvestmentRegion())
                    .establishDate(fund.getEstablishDate())
                    .fundRelease(fundPolicy.getFundRelease())   // fundRelease 사용!
//                    .launchDate(fundPolicy.getFundRelease())  // deprecated
                    .nav(fund.getNav())
                    .aum(fund.getAum())
                    .totalExpenseRatio(fund.getTotalExpenseRatio())
                    .riskLevel(fund.getRiskLevel())
                    .managementCompany(fund.getManagementCompany())

                    // FundPolicy 추가 정보
                    .fundTheme(fundPolicy.getFundTheme())

                    // 수익률 정보
                    .return1m(fundReturn != null ? fundReturn.getReturn1m() : null)
                    .return3m(fundReturn != null ? fundReturn.getReturn3m() : null)
                    .return6m(fundReturn != null ? fundReturn.getReturn6m() : null)
                    .return12m(fundReturn != null ? fundReturn.getReturn12m() : null)
                    .returnSince(fundReturn != null ? fundReturn.getReturnSince() : null)
                    .build();
        });
    }

    /**
     * 문자열 리스트를 Integer 리스트로 변환
     * null이거나 빈 리스트면 null 반환 (필터 적용 안함)
     */
    private List<Integer> convertToIntegerList(
            List<String> stringList
    ) {
        if (stringList == null || stringList.isEmpty()) {
            return null;
        }

        return stringList.stream()
                .map(Integer::parseInt)
                .collect(Collectors.toList());
    }

    /**
     * 빈 리스트 처리 - null이거나 빈 리스트면 null 반환
     */
    private List<String> processEmptyList(
            List<String> list
    ) {
        return (list == null || list.isEmpty()) ? null : list;
    }

    /**
     * 펀드 ID로 펀드 존재 여부 확인
     */
    public boolean existsFund(Long fundId) {
        log.debug("펀드 존재 여부 확인 - fundId: {}", fundId);
        return fundRepository.existsByFundId(fundId);
    }

    /**
     * 펀드 ID로 위험등급 조회
     */
    public Optional<Integer> getFundRiskLevel(Long fundId) {
        log.debug("펀드 위험등급 조회 - fundId: {}", fundId);
        return fundRepository.findRiskLevelByFundId(fundId);
    }

    /**
     * 펀드 상세 정보 조회 (투자성향 검증 포함)
     */
    // Integer investType
    public FundDetailResponseDTO getFundDetail(Long fundId) {

        // 1. 펀드 기본 정보 조회
        Optional<Fund> fundOpt = fundRepository.findByFundId(fundId);
        if (!fundOpt.isPresent()) {
            return FundDetailResponseDTO.builder()
                    .accessAllowed(false)
                    .accessMessage("존재하지 않는 펀드입니다.")
                    .build();
        }

        Fund fund = fundOpt.get();

        // 2. 전체 정보 조회
        FundDetailResponseDTO.FundDetailResponseDTOBuilder builder = FundDetailResponseDTO.builder()
                .fundId(fund.getFundId())
                .fundName(fund.getFundName())
                .fundType(fund.getFundType())
                .investmentRegion(fund.getInvestmentRegion())
                .establishDate(fund.getEstablishDate())
                .launchDate(fund.getLaunchDate())
                .nav(fund.getNav())
                .aum(fund.getAum())
                .totalExpenseRatio(fund.getTotalExpenseRatio())
                .riskLevel(fund.getRiskLevel())
                .managementCompany(fund.getManagementCompany())
                .accessAllowed(true);

        // 3. 수익률 정보 조회
        Optional<FundReturn> fundReturnOpt = fundReturnRepository.findOptionalByFund_FundId(fundId);
        if (fundReturnOpt.isPresent()) {
            FundReturn fundReturn = fundReturnOpt.get();
            builder.return1m(fundReturn.getReturn1m())
                    .return3m(fundReturn.getReturn3m())
                    .return6m(fundReturn.getReturn6m())
                    .return12m(fundReturn.getReturn12m())
                    .returnSince(fundReturn.getReturnSince());
        } else {
            log.warn("수익률 정보 없음 - fundId: {}", fundId);
        }

        // 4. 포트폴리오 정보 조회
        Optional<FundPortfolio> portfolioOpt = fundPortfolioRepository.findByFundId(fundId);
        if (portfolioOpt.isPresent()) {
            FundPortfolio portfolio = portfolioOpt.get();
            builder.domesticStock(portfolio.getDomesticStock())
                    .overseasStock(portfolio.getOverseasStock())
                    .domesticBond(portfolio.getDomesticBond())
                    .overseasBond(portfolio.getOverseasBond())
                    .fundInvestment(portfolio.getFundInvestment())
                    .liquidity(portfolio.getLiquidity());
        } else {
            log.warn("포트폴리오 정보 없음 - fundId: {}", fundId);
        }

        log.info("펀드 상세 정보 조회 완료 - fundId: {}", fundId);
        return builder.build();
    }

    //펀드 수정 메서드
    @Transactional
    public void updateFundAdmin(Long fundId,
                                String fundTheme,
                                MultipartFile fileTerms,
                                MultipartFile fileManual,
                                MultipartFile fileProspectus) throws IOException {

        // 1. 정책 저장/수정
        FundPolicy policy = fundPolicyRepository.findByFund_FundId(fundId)
                .orElseGet(() -> FundPolicy.builder()
                        .fund(fundRepository.findByFundId(fundId)
                                .orElseThrow(() -> new RuntimeException("펀드 없음")))
                        .build());
        policy.setFundTheme(fundTheme);
        fundPolicyRepository.save(policy);

        // 2. 문서 교체 (있을 때만)
        if (fileTerms != null && !fileTerms.isEmpty()) {
            replaceDocument(fundId, "약관", fileTerms);
        }
        if (fileManual != null && !fileManual.isEmpty()) {
            replaceDocument(fundId, "상품설명서", fileManual);
        }
        if (fileProspectus != null && !fileProspectus.isEmpty()) {
            replaceDocument(fundId, "투자설명서", fileProspectus);
        }
    }

    @Transactional
    public void replaceDocument(Long fundId, String docType, MultipartFile newFile) throws IOException {
        // 기존 문서 삭제 (있다면)
        fundDocumentRepository.deleteByFund_FundIdAndDocType(fundId, docType);
        // 새 문서 저장 (이미 있는 saveFundDocument 재사용)
        Fund fund = fundRepository.findByFundId(fundId)
                .orElseThrow(() -> new RuntimeException("펀드 없음"));
        saveFundDocument(fund, newFile, docType);
    }

}
