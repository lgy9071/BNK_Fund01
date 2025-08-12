package com.example.ap.service.fund;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.ap.repository.fund.FundFavoriteRepository;
import com.example.ap.repository.fund.UserRepository;
import com.example.common.entity.fund.Fund;
import com.example.common.entity.fund.FundFavorite;
import com.example.common.entity.fund.User;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundFavoriteService {

    private final FundFavoriteRepository favoriteRepo;
    private final UserRepository userRepo;
    private final FundRepository fundRepo;

    /* 관심 목록 */
    public List<Fund> list(int userId) {
        User user = userRepo.findById(userId).orElseThrow();
        return favoriteRepo.findByUser(user)
                .stream()
                .map(FundFavorite::getFund)
                .toList();
    }

    /* 관심 토글 */
    @Transactional
    public void toggle(int userId, int fundId) {
        User user  = userRepo.findById(userId)        .orElseThrow();
        Fund fund  = fundRepo.findById((long) fundId) .orElseThrow();

        favoriteRepo.findByUserAndFund(user, fund)
                .ifPresentOrElse(
                        favoriteRepo::delete,
                        () -> favoriteRepo.save(
                                FundFavorite.builder()
                                        .user(user)
                                        .fund(fund)
                                        .build()));
    }

    /* 상세 페이지용: 이미 관심 등록 여부 */
    public boolean isFavorite(int userId, long fundId) {
        User user = userRepo.findById(userId).orElseThrow();
        Fund fund = fundRepo.findById(fundId).orElseThrow();
        return favoriteRepo.findByUserAndFund(user, fund).isPresent();
    }
}

