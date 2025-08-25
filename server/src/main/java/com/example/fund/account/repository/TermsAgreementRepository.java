package com.example.fund.account.repository;

import java.time.LocalDateTime;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

import com.example.fund.account.entity.TermsAgreement;

public interface TermsAgreementRepository extends JpaRepository<TermsAgreement, Long> {
	
//	Optional<TermsAgreement> findFirstByUserIdAndProductIdAndIsActiveTrue(Integer userId, Long productId);
	
	// 이력 최신 1건 조회(필요시)
//	Optional<TermsAgreement> findTopByUserIdAndProductIdOrderByAgreeIdDesc(Integer userId, Long productId);
	
//	@Modifying
//	@Query("UPDATE TermsAgreement t SET t.isActive = false WHERE t.isActive = true")
//	int expireAllActive();
	
	Optional<TermsAgreement> findTopByUserIdAndProductIdAndIsActiveIsTrueAndExpiredAtAfterOrderByAgreedAtDesc(
		    Integer userId, Long productId, LocalDateTime now);

}
