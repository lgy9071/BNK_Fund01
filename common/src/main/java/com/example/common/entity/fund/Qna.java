package com.example.common.entity.fund;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Entity
@Table(name="tbl_qna")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class Qna extends BaseEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer qnaId;
	
	@ManyToOne(fetch = FetchType.LAZY)
	@JoinColumn(name = "user_id" , nullable = false) // fk 칼럼 이름
	private User user;
	
	@Column(nullable = false)
	private String title;
	private String content;
	
	@Column(nullable = false, columnDefinition = "VARCHAR(10) DEFAULT '대기'")
	private String status = "대기";
	
	@Column
	private String answer;
}
