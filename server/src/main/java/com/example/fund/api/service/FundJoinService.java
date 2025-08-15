package com.example.fund.api.service;

import org.springframework.stereotype.Service;

import com.example.fund.api.entity.TermsAgreement;
import com.example.fund.api.repository.TermsAgreementRepository;
import com.example.fund.fund.entity.FundDocument;
import com.example.fund.fund.repository.FundDocumentRepository;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;

import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class FundJoinService {
	
	private final TermsAgreementRepository termsAgreementRepo;
	private final UserRepository userRepo;
	private final FundDocumentRepository fundDocumentRepo; 
	
	//입출금 계좌 소유 확인
	
	// 약관 이력
	@Transactional
	public void termsAgree(int userId, Long docId) {
		User user = userRepo.findByUserId(userId).orElseThrow();
		FundDocument doc = fundDocumentRepo.findById(docId).orElseThrow();
		TermsAgreement termsAgreement = TermsAgreement.builder()
				.user(user)
				.document(doc)
				.build();
		termsAgreementRepo.save(termsAgreement);
		
				
	}
	
	
}
