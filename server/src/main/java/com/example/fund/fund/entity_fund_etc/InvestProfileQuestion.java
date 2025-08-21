package com.example.fund.fund.entity_fund_etc;

import jakarta.persistence.*;
import lombok.*;

import java.util.List;

@Entity
@Table(name = "invest_profile_question")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class InvestProfileQuestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer questionId;

    @Column(length = 255, nullable = false)
    private String content; // 질문 내용

    @OneToMany(mappedBy = "question", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<InvestProfileOption> options;
}