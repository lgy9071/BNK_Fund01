package com.example.common.entity.fund;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "invest_profile")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@ToString
public class InvestProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "question_id")
    private Integer questionId;

    @Column(length = 255, nullable = false)
    private String question;

    @Column(length = 255, nullable = false)
    private String selection;

    @Column(nullable = false)
    private Integer score;
}