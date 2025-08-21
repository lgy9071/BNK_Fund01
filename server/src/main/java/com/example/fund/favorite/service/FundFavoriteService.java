package com.example.fund.favorite.service;

import com.example.fund.favorite.entity.FundFavorite;
import com.example.fund.favorite.repository.FundFavoriteRepository;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.fund.repository_fund.FundRepository;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

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
    /*
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
    */

    /* 상세 페이지용: 이미 관심 등록 여부 */
    /*
    public boolean isFavorite(int userId, long fundId) {
        User user = userRepo.findById(userId).orElseThrow();
        Fund fund = fundRepo.findById(fundId).orElseThrow();
        return favoriteRepo.findByUserAndFund(user, fund).isPresent();
    }
    */
}
