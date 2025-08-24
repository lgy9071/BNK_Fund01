package com.example.fund.fund.repository_fund;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.fund.entity_fund_etc.FundHolding;


public interface FundHoldingRepository extends JpaRepository<FundHolding, Long>{
    @Query(value = """
        select case when count(1) > 0 then 1 else 0 end
        from FUND_HOLDING fh
        where fh.USER_ID = :userId
          and fh.FUND_ID = :fundId
          and NVL(fh.QUANTITY,0) > 0
        """, nativeQuery = true)
    int canReview(@Param("userId") Integer userId, @Param("fundId") String fundId);

    List<FundHolding> findByUser_UserId(Integer userId);
}
