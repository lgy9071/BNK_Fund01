package com.example.fund.account.service;


import com.example.fund.account.dto.MyFundDto;
import com.example.fund.account.entity.FundAccount;
import com.example.fund.account.repository.FundAccountRepository;
import com.example.fund.fund.entity_fund.FundStatusDaily;
import com.example.fund.fund.repository_fund.FundStatusDailyRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MyFundService {

    private final FundAccountRepository fundAccountRepository;
    private final FundStatusDailyRepository fundStatusDailyRepository;

    /**
     * 사용자의 가입 펀드 목록 조회
     *
     * @param userId 사용자 ID
     * @return 가입 펀드 목록 (수익률 계산 포함)
     */
    public List<MyFundDto> getMyFunds(Integer userId) {
        log.info("사용자 {}의 가입 펀드 목록 조회 시작", userId);

        // 1. 사용자의 활성 펀드 계좌 조회 (페치 조인으로 N+1 문제 해결)
        List<FundAccount> fundAccounts = fundAccountRepository
                .findByUserIdWithFundInfo(userId, FundAccount.FundAccountStatus.NORMAL);

        if (fundAccounts.isEmpty()) {
            log.info("사용자 {}의 가입 펀드가 없음", userId);
            return List.of();
        }

        // 2. 펀드 ID 목록 추출
        List<String> fundIds = fundAccounts.stream()
                .map(account -> account.getFundProduct().getFund().getFundId())
                .distinct()
                .collect(Collectors.toList());

        // 3. 최신 기준가 정보 조회
        List<FundStatusDaily> latestNavPrices = fundStatusDailyRepository
                .findLatestByFundIds(fundIds);

        // 4. 펀드별 최신 기준가 맵 생성
        Map<String, BigDecimal> navPriceMap = latestNavPrices.stream()
                .collect(Collectors.toMap(
                        fsd -> fsd.getFund().getFundId(),
                        FundStatusDaily::getNavPrice
                ));

        // 5. 각 계좌별로 DTO 생성 (수익률 계산 포함)
        List<MyFundDto> result = fundAccounts.stream()
                .map(account -> buildMyFundDto(account, navPriceMap))
                .collect(Collectors.toList());

        log.info("사용자 {}의 가입 펀드 {}개 조회 완료", userId, result.size());
        return result;
    }

    /**
     * FundAccount를 MyFundDto로 변환 (수익률 계산 포함)
     */
    private MyFundDto buildMyFundDto(FundAccount account, Map<String, BigDecimal> navPriceMap) {
        String fundId = account.getFundProduct().getFund().getFundId();
        String fundName = account.getFundProduct().getFund().getFundName();

        // 현재 평가액 계산
        BigDecimal currentValuation = calculateCurrentValuation(account, navPriceMap);

        // 수익률 계산
        Double currentRate = calculateReturnRate(account.getTotalInvested(), currentValuation);

        return MyFundDto.builder()
                .fundId(account.getFundAccountId())  // Flutter에서 id로 사용
                .fundName(fundName)
                .currentRate(currentRate)
                .currentBalance(currentValuation.intValue())  // Flutter에서는 int로 처리
                .joinedDate(account.getCreatedAt())
                .fundCode(fundId)
                .units(account.getUnits())
                .totalInvested(account.getTotalInvested())
                .fundValuation(currentValuation)
                .build();
    }

    /**
     * 현재 평가액 계산
     */
    private BigDecimal calculateCurrentValuation(FundAccount account, Map<String, BigDecimal> navPriceMap) {
        String fundId = account.getFundProduct().getFund().getFundId();
        BigDecimal latestNavPrice = navPriceMap.get(fundId);

        if (latestNavPrice != null) {
            // 최신 기준가 × 보유 좌수
            return account.getUnits().multiply(latestNavPrice)
                    .setScale(0, RoundingMode.HALF_UP);
        } else {
            // 최신 기준가 정보가 없으면 기존 평가액 사용
            log.warn("펀드 {}의 최신 기준가 정보 없음, 기존 평가액 사용", fundId);
            return account.getFundValuation();
        }
    }

    /**
     * 수익률 계산 (총 수익률 %)
     */
    private Double calculateReturnRate(BigDecimal totalInvested, BigDecimal currentValuation) {
        if (totalInvested.compareTo(BigDecimal.ZERO) == 0) {
            return 0.0;  // 투자금액이 0이면 수익률 0%
        }

        // ((현재평가액 - 총투자금액) / 총투자금액) × 100
        BigDecimal profit = currentValuation.subtract(totalInvested);
        BigDecimal rate = profit.divide(totalInvested, 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100));

        return rate.doubleValue();
    }
}