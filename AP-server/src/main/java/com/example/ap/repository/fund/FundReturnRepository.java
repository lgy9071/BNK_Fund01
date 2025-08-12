package com.example.ap.repository.fund;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.common.entity.fund.FundReturn;

public interface FundReturnRepository extends JpaRepository<FundReturn, Long> {
    /** 펀드 ID로 수익률 조회 */
    FundReturn findByFund_FundId(Long fundId);

    /** 펀드 ID로 수익률 조회 (Optional) */
    Optional<FundReturn> findOptionalByFund_FundId(Long fundId);

    /**
     * 여러 fundId에 대한 FundReturn을 배치로 조회 (N+1 문제 해결)
     * @param fundIds 조회할 펀드 ID 리스트
     * @return 해당 펀드들의 수익률 정보 리스트
     */
    @Query("SELECT fr FROM FundReturn fr WHERE fr.fund.fundId IN :fundIds")
    List<FundReturn> findByFund_FundIdIn(@Param("fundIds") List<Long> fundIds);
}
