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
@Table(name = "deposit_account")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DepositAccount {

	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY) // AUTO_INCREMENT
	@Column(name = "account_id", nullable = false)
	private Long accountId;              // 계좌 고유 ID

	@ManyToOne(fetch = FetchType.LAZY, optional = false)
	@JoinColumn(name = "user_id", nullable = false) // 회원 테이블 FK
	private User user;                   // 사용자 ID

	@Column(name = "account_number", length = 20, nullable = false, unique = true)
	private String accountNumber;        // 계좌번호 (자동생성, UNIQUE)

	@Column(name = "account_name", length = 50)
	private String accountName;          // 계좌 별칭 (nullable)

	@Column(name = "pin_hash", length = 60, nullable = false)
	private String pinHash;              // 계좌 비밀번호(BCrypt 해시 60자)

	@Column(name = "balance", precision = 18, scale = 2, nullable = false)
	private BigDecimal balance;          // 현재 잔액 (기본 0.00)

	@CreationTimestamp
	@Column(name = "created_at", nullable = false, updatable = false)
	private LocalDateTime createdAt;     // 계좌 등록일 (DB 기본값 CURRENT_TIMESTAMP)

	@Enumerated(EnumType.STRING)
	@Column(name = "status", nullable = false)
	private AccountStatus status;        // 계좌 처리 상태 (PENDING/POSTED/VOID)

	public enum AccountStatus {
		PENDING, // 처리 대기/승인 전
		POSTED,  // 완료/확정
		VOID     // 무효/취소
	}
}



/*
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
	
    @Column(name = "balance", precision = 18, scale = 0, nullable = false)
	private BigDecimal balance; // 현재 잔액
	
    @CreationTimestamp // entity 처음 생성 시 시간 자동 등록
    @Column(name = "registered_at", nullable = false, updatable = false)
	private LocalDateTime createdAt; // 계좌 등록일
    
    @Enumerated(EnumType.STRING)
    @Column(name="status", length=10, nullable=false)
	private AccountStatus status; // 계좌 상태 (정상, 정지, 해지)

    
    public enum AccountStatus {
    	ACTIVE, // 정상
    	FROZEN, // 정지
    	CLOSED // 해지
    }
}
*/