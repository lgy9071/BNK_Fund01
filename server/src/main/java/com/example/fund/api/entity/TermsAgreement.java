package com.example.fund.api.entity;

import java.time.LocalDateTime;

import com.example.fund.fund.entity_fund.FundDocument;
import com.example.fund.user.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "terms_agreement")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TermsAgreement {
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long agreeId;
	
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name="user_id", nullable=false)
	private User user;
	
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name="document_id", nullable=false)
	private FundDocument document;
	
	@Column(name="agreed_at", updatable=false, nullable=false)
	private LocalDateTime agreedAt;
	
	@Column(name="is_active", nullable=false)
	@Builder.Default
	private boolean isActive = true; // true: 유효, false: 만료/철회
	
	@PrePersist
	public void onCreate() {
		this.agreedAt = LocalDateTime.now();
	}
}
