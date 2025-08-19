package com.example.fund.fund.entity_fund_etc;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "invest_profile_option")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InvestProfileOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer optionId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "question_id", nullable = false)
    private InvestProfileQuestion question;

    @Column(length = 255, nullable = false)
    private String content; // 보기 텍스트

    @Column(nullable = false)
    private Integer score; // 점수
}