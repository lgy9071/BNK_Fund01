package com.example.fund.favorite.repository;

import com.example.fund.favorite.entity.FundFavorite;
import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface FundFavoriteRepository extends JpaRepository<FundFavorite, Long> {
    List<FundFavorite> findByUser(User user);
    Optional<FundFavorite> findByUserAndFund(User user, Fund fund);
    void deleteByUserAndFund(User user, Fund fund);
}
