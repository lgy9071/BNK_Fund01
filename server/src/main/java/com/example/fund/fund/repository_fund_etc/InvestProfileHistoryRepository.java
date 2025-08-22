package com.example.fund.fund.repository_fund_etc;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.fund.admin.repository.projection.InvestorProfileStat;
import com.example.fund.fund.entity_fund_etc.InvestProfileHistory;
import com.example.fund.user.entity.User;

public interface InvestProfileHistoryRepository extends JpaRepository<InvestProfileHistory, Integer> {
    Page<InvestProfileHistory> findByUser(User user, Pageable pageable);

        @Query(value = """
        SELECT TYPE_ID as typeId, COUNT(*) as cnt
        FROM INVEST_PROFILE_HISTORY
        GROUP BY TYPE_ID
        ORDER BY TYPE_ID
        """, nativeQuery = true)
    List<InvestorProfileStat> countByType();

}
