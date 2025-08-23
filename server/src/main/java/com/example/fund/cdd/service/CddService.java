package com.example.fund.cdd.service;

import com.example.fund.cdd.dto.CddRequestDto;
import com.example.fund.cdd.dto.CddResponseDto;
import com.example.fund.cdd.entity.CddEntity;
import com.example.fund.cdd.repository.CddRepository;
import com.example.fund.cdd.util.AESUtil;
import jakarta.transaction.Transactional;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

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

            // 2. 중복 CDD 확인
            Optional<CddEntity> existingCdd = cddRepository.findByUserIdAndRrn(
                    request.getUserId(), encryptedRrn);

            if (existingCdd.isPresent()) {
                log.warn("이미 CDD가 완료된 사용자입니다 - 사용자 ID: {}", request.getUserId());
                throw new IllegalStateException("이미 고객확인의무가 완료된 사용자입니다.");
            }

            // 3. 위험도 스코어링 수행 (임시 구현)
            RiskAssessmentResult riskResult = performRiskScoring(request);

            // 4. CDD 엔티티 생성 및 저장
            CddEntity cddEntity = CddEntity.builder()
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

            CddEntity savedEntity = cddRepository.save(cddEntity);

            log.info("CDD 처리 완료 - CDD ID: {}, 위험등급: {}",
                    savedEntity.getCddId(), savedEntity.getRiskLevel());

            // 5. 응답 DTO 생성
            return CddResponseDto.builder()
                    .cddId(savedEntity.getCddId().toString()) // Long -> String 변환
                    .riskLevel(savedEntity.getRiskLevel())
                    .processedAt(savedEntity.getCreatedAt().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .build();

        } catch (IllegalStateException e) {
            throw e; // 중복 CDD 예외는 그대로 전파
        } catch (Exception e) {
            log.error("CDD 처리 중 오류 발생", e);
            throw new RuntimeException("CDD 처리 중 시스템 오류가 발생했습니다.", e);
        }
    }

    /**
     * 위험도 스코어링 로직 (임시 구현)
     * TODO: 실제 스코어링 로직 구현 필요
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

    // 기존 getCddHistory 메서드 제거 (불필요)

    // 위험도 평가 결과 내부 클래스
    @Data
    @AllArgsConstructor
    private static class RiskAssessmentResult {
        private Integer riskScore;
        private String riskLevel;
    }
}