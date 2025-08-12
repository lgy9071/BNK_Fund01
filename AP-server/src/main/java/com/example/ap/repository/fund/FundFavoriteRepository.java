package com.example.ap.repository.fund;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.Fund;
import com.example.common.entity.fund.FundFavorite;
import com.example.common.entity.fund.User;



public interface FundFavoriteRepository extends JpaRepository<FundFavorite, Long> {
    List<FundFavorite> findByUser(User user);
    Optional<FundFavorite> findByUserAndFund(User user, Fund fund);
    void deleteByUserAndFund(User user, Fund fund);
}
