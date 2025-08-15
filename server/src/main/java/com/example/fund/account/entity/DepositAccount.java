package com.example.fund.account.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.hibernate.annotations.CreationTimestamp;

import com.example.fund.user.entity.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
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
@Table(name="deposit_account")
@Setter
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DepositAccount {
	
	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	@Column(name="account_id")
	private Long accountId; // 계좌 고유 ID
	
	@ManyToOne(fetch=FetchType.LAZY)
	@JoinColumn(name="user_id", nullable=false)
	private User user; // 사용자 ID
	
	@Column(name= "account_number", unique=true)
	private String accountNumber;
	
	@Column(name="pin_hash")
	private Integer pinHash;
	  
	private BigDecimal balance; // 현재 잔액
	
    @CreationTimestamp // entity 처음 생성 시 시간 자동 등록
    @Column(name = "registered_at", nullable = false, updatable = false)
	private LocalDateTime createdAt; // 계좌 등록일
    
    @Enumerated(EnumType.STRING)
    @Column(name="status", length=10, nullable=false)
	private AccountStatus status; // 계좌 상태 (정상, 정지, 해지)
    
    
    @PrePersist
    protected void onCreate() {
    	if (status == null) status = AccountStatus.ACTIVE;
    }
    
    public enum AccountStatus {
    	ACTIVE, // 정상
    	FROZEN, // 정지
    	CLOSED // 해지
    }
}