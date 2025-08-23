package com.example.fund.cdd.service;

import com.example.fund.cdd.dto.CddHistoryResponseDto;
import com.example.fund.cdd.dto.CddRequestDto;
import com.example.fund.cdd.dto.CddResponseDto;
import com.example.fund.cdd.entity.CddEntity;
import com.example.fund.cdd.repository.CddRepository;
import com.example.fund.cdd.util.AESUtil;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@Transactional
@RequiredArgsConstructor
@Slf4j
public class CddService {

    private final CddRepository cddRepository;
    private final AESUtil aesUtil;

    /**
     * CDD 실시 및 저장
     */
    public CddResponseDto processCdd(CddRequestDto request) {
        log.info("CDD 처리 시작 - 사용자 ID: {}", request.getUserId());

        try {
            // 1. 주민등록번호 암호화
            String encryptedRrn = aesUtil.encrypt(request.getResidentRegistrationNumber());

            // 2. 기존 CDD 이력 확인
            Optional<CddEntity> existingCdd = cddRepository.findByUserIdAndRrn(
                    request.getUserId(), encryptedRrn);

            // 3. 위험도 스코어링 수행 (임시 구현)
            RiskAssessmentResult riskResult = performRiskScoring(request);

            CddEntity savedEntity;

            if (existingCdd.isPresent()) {
                // 4-1. 기존 이력 업데이트
                log.info("기존 CDD 이력 업데이트 - CDD ID: {}", existingCdd.get().getCddId());

                CddEntity entity = existingCdd.get();
                entity.setAddress(request.getAddress());
                entity.setNationality(request.getNationality());
                entity.setOccupation(request.getOccupation());
                entity.setIncomeSource(request.getIncomeSource());
                entity.setTransactionPurpose(request.getTransactionPurpose());
                entity.setRiskLevel(riskResult.getRiskLevel());
                entity.setRiskScore(riskResult.getRiskScore());
                // created_at은 그대로 유지, updated_at은 자동 업데이트

                savedEntity = cddRepository.save(entity);

            } else {
                // 4-2. 새로운 CDD 이력 생성
                log.info("새로운 CDD 이력 생성 - 사용자 ID: {}", request.getUserId());

                CddEntity entity = CddEntity.builder()
                        .userId(request.getUserId())
                        .rrn(encryptedRrn)
                        .address(request.getAddress())
                        .nationality(request.getNationality())
                        .occupation(request.getOccupation())
                        .incomeSource(request.getIncomeSource())
                        .transactionPurpose(request.getTransactionPurpose())
                        .riskLevel(riskResult.getRiskLevel())
                        .riskScore(riskResult.getRiskScore())
                        .build();

                savedEntity = cddRepository.save(entity);
            }

            log.info("CDD 처리 완료 - CDD ID: {}, 위험등급: {}, 처리방식: {}",
                    savedEntity.getCddId(), savedEntity.getRiskLevel(),
                    existingCdd.isPresent() ? "업데이트" : "신규생성");

            // 5. 응답 DTO 생성
            return CddResponseDto.builder()
                    .cddId(savedEntity.getCddId().toString()) // Long -> String 변환
                    .riskLevel(savedEntity.getRiskLevel())
                    .processedAt(savedEntity.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .build();

        } catch (Exception e) {
            log.error("CDD 처리 중 오류 발생", e);
            throw new RuntimeException("CDD 처리 중 시스템 오류가 발생했습니다.", e);
        }
    }

    /**
     * 위험도 스코어링 로직 (임시 구현)
     */
    private RiskAssessmentResult performRiskScoring(CddRequestDto request) {
        log.info("위험도 스코어링 수행 중...");

        // TODO: 실제 스코어링 로직 구현
        // - 국적별 위험도 (해외 고위험 국가 여부)
        // - 직업별 위험도 (고위험 업종 여부)
        // - 소득원별 위험도
        // - 거래목적별 위험도
        // - 나이별 위험도 (주민등록번호에서 추출)
        // - 종합 위험도 점수 계산

        // 임시로 모든 사용자를 "MEDIUM" 등급으로 분류 (테이블 명세 예시에 맞춤)
        int riskScore = 85; // 0-100 점수 (낮을수록 안전)
        String riskLevel = "MEDIUM"; // LOW, MEDIUM, HIGH

        log.info("위험도 평가 완료 - 점수: {}, 등급: {}", riskScore, riskLevel);

        return new RiskAssessmentResult(riskScore, riskLevel);
    }

    /**
     * 사용자별 CDD 이력 조회
     */
    @Transactional(readOnly = true)
    public List<CddHistoryResponseDto> getCddHistory(Long userId) {
        log.info("CDD 이력 조회 - 사용자 ID: {}", userId);

        List<CddEntity> cddList = cddRepository.findByUserIdOrderByCreatedAtDesc(userId);

        return cddList.stream()
                .map(entity -> {
                    // 주민등록번호 복호화 후 마스킹
                    String decryptedRrn = aesUtil.decrypt(entity.getRrn());
                    String maskedRrn = aesUtil.maskRrn(decryptedRrn);

                    return CddHistoryResponseDto.builder()
                            .cddId(entity.getCddId().toString())
                            .maskedRrn(maskedRrn)
                            .nationality(entity.getNationality())
                            .occupation(entity.getOccupation())
                            .incomeSource(entity.getIncomeSource())
                            .transactionPurpose(entity.getTransactionPurpose())
                            .riskLevel(entity.getRiskLevel())
                            .riskScore(entity.getRiskScore())
                            .processedAt(entity.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                            .build();
                })
                .collect(Collectors.toList());
    }

    // 위험도 평가 결과 내부 클래스
    @Data
    @AllArgsConstructor
    private static class RiskAssessmentResult {
        private Integer riskScore;
        private String riskLevel;
    }
}