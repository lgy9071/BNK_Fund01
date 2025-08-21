package com.example.fund.fund.service;

import com.example.fund.fund.dto.FundDetailResponse;
import com.example.fund.fund.dto.FundDetailResponseDTO;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.repository_fund.FundRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class FundService {

    private final FundRepository fundRepository;

    /**
     * PDF 저장 & JPG 변환
     */
    private final String UPLOAD_DIR = "C:\\bnk_project\\data\\uploads\\fund_document\\";

    /**
     * 특정 펀드 ID 조회
     */
    public Optional<Fund> findById(String id) {
        return fundRepository.findById(id);
    }

    /**
     * 펀드 등록
     */
    public Fund save(Fund fund) {
        return fundRepository.save(fund);
    }

    /** 펀드 정보 수정 */
    /*
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
    */

    /**
     * 특정 펀드 삭제
     */
    public void delete(String id) {
        fundRepository.deleteById(id);
    }

    /** 펀드 등록 & 공시 자료 등록 */
    /*
    @Transactional
    public String registerFundWithAllDocuments(
            FundRegisterRequest request,
            MultipartFile fileTerms,
            MultipartFile fileManual,
            MultipartFile fileProspectus
    ) throws IOException {
        Fund fund = fundRepository.findByFundId("1").orElseThrow(() -> new IllegalArgumentException("존재하지 않는 펀드 ID"));

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
    */

    /** 공시 자료 등록 */
    /*
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
    */

    /** PDF -> JPG 변환 */
    /*
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
    */

    /** 투자 성향 + 필터링 조건을 모두 적용한 펀드 목록 조회 투자성향 (1~5) */
    /*
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
    */

    /** FundPolicy 페이지를 FundResponseDTO 페이지로 변환 */
    /*
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
    */

    /** 투자 성향에 따른 펀드 목록 조회 - pagination */
    /*
    public Page<FundPolicyResponseDTO> findByInvestType(
            Integer investType,
            Pageable pageable
    ) {
        int startRiskLevel;
        int endRiskLevel = 6;

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
    */

    /** List<Fund>를 List<FundResponseDTO>로 변환하는 메서드 */
    /*
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
    */

    /** Page<Fund>를 Page<FundResponseDTO>로 변환하는 메서드 */
    /*
    private Page<FundPolicyResponseDTO> convertToFundResponseDTO(Page<Fund> fundPage) {
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
    */

    /** 펀드 수정 메서드 */
    /*
    @Transactional
    public void updateFundAdmin(
            String fundId,
            String fundTheme,
            MultipartFile fileTerms,
            MultipartFile fileManual,
            MultipartFile fileProspectus
    ) throws IOException {
        FundPolicy policy = fundPolicyRepository.findByFund_FundId(fundId)
                .orElseGet(() -> FundPolicy.builder()
                        .fund(fundRepository.findByFundId(fundId)
                                .orElseThrow(() -> new RuntimeException("펀드 없음")))
                        .build());
        policy.setFundTheme(fundTheme);
        fundPolicyRepository.save(policy);

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
    */

    /**
     * 새로운 메서드 - 투자 성향 + 필터링 조건을 모두 적용한 펀드 목록 조회
     */
    public FundDetailResponse getFundDetailBasic(String fundId) {
        Fund fund = fundRepository.findByFundId(fundId).orElseThrow(() -> new RuntimeException("펀드를 찾을 수 없습니다."));

        Long termsFileId = null;
        Long manualFileId = null;
        Long prospectusFileId = null;
        String termsFileName = null;
        String manualFileName = null;
        String prospectusFileName = null;

        return FundDetailResponse.builder()
                .build();

        /*
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
         */
    }

    /**
     * 문자열 리스트를 Integer 리스트로 변환
     */
    private List<Integer> convertToIntegerList(List<String> stringList) {
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
    private List<String> processEmptyList(List<String> list) {
        return (list == null || list.isEmpty()) ? null : list;
    }

    /**
     * 펀드 ID로 펀드 존재 여부 확인
     */
    public boolean existsFund(String fundId) {
        log.debug("펀드 존재 여부 확인 - fundId: {}", fundId);
        return fundRepository.existsByFundId(fundId);
    }

    /**
     * 펀드 ID로 위험등급 조회
     */
    public Optional<Integer> getFundRiskLevel(String fundId) {
        return fundRepository.findRiskLevelByFundId(fundId);
    }

    /**
     * 펀드 상세 정보 조회 (투자성향 검증 포함)
     */
    public FundDetailResponseDTO getFundDetail(String fundId) {
        return FundDetailResponseDTO.builder().build();
    }

}

