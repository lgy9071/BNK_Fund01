package com.example.fund.fund.entity_fund_etc;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "invest_profile_type")
@Getter
@Setter
public class InvestProfileType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long typeId;

    @Column(length = 20, nullable = false)
    private String typeName; // 안정형, 위험중립형, ...

    @Column(nullable = false)
    private Integer minScore;

    @Column(nullable = false)
    private Integer maxScore;

    @Column(name = "risk_level", nullable = false)
    private Integer riskLevel; // ★ 추가: 1~5

    @Lob
    private String description;
}