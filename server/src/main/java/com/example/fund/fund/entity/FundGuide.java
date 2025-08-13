package com.example.fund.fund.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "fund_guide")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class FundGuide {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer guide_id; // 기본키
    
    @Column(nullable = false, length = 50)
    private String category; // 분류: 유형 / 용어해설 등

    @Column(nullable = false, length = 100)
    private String term; // 펀드 용어

    @Lob
    @Column(nullable = false, columnDefinition = "CLOB")
    private String definition; // 용어 해설
}
