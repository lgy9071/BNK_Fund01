package com.example.fund.fund.repository_fund;

import com.example.fund.fund.entity_fund.FundReturn;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FundReturnRepository extends JpaRepository<FundReturn, Long> {
    /** 펀드 ID로 수익률 조회 */
    FundReturn findByFund_FundId(String fundId);

    /** 펀드 ID로 수익률 조회 (Optional) */
    Optional<FundReturn> findOptionalByFund_FundId(String fundId);

    /** 여러 fundId에 대한 FundReturn 배치로 조회 (N+1 문제 해결) */
    @Query("SELECT fr FROM FundReturn fr WHERE fr.fund.fundId IN :fundIds")
    List<FundReturn> findByFund_FundIdIn(@Param("fundIds") List<String> fundIds);

    // 최신 기준일 1건
    Optional<FundReturn> findTopByFund_FundIdOrderByBaseDateDesc(String fundId);
}
