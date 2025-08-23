package com.example.fund.account.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.account.entity.FundAccount;
import com.example.fund.fund.entity_fund.FundProduct;

public interface FundAccountRepository extends JpaRepository<FundAccount, Long> {
	
	boolean existsByFundAccountNumber(String fundAccountNumber);
	
	Optional<FundAccount> findByUser_UserIdAndFundProduct_ProductId(Integer userId, Long productId);

}
