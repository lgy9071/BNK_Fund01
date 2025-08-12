package com.example.common.entity.fund;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.ToString;

@Entity
@Table(name="tbl_faq")
@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
@ToString
public class Faq extends BaseEntity {
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Integer faqId;
	
	private String question;
	private String answer;
	
	@Column(nullable = false)
    private Integer viewCount = 0;

	@Column(nullable = false)
	private Boolean active = true;

}
