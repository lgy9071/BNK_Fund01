package com.example.fund.fund.entity_fund_etc;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "invest_profile_type")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class InvestProfileType {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long typeId;

    @Column(length = 20, nullable = false)
    private String typeName; // 예: 안정형

    @Column(nullable = false)
    private Integer minScore;

    @Column(nullable = false)
    private Integer maxScore;

    @Lob
    private String description;
}