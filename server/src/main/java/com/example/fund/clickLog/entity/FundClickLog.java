package com.example.fund.clickLog.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "FUND_CLICK_LOG")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class FundClickLog {

    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "FCL_SEQ")
    @SequenceGenerator(name = "FCL_SEQ", sequenceName = "SEQ_FUND_CLICK_LOG", allocationSize = 1)
    @Column(name = "CLICK_LOG_ID")
    private Long id;

    @Column(name = "FUND_ID", nullable = false)
    private Long fundId;

    @Column(name = "USER_ID", nullable = false)
    private Long userId;

    @Column(name = "CLICK_DT", nullable = false)
    private OffsetDateTime clickDt;

    @PrePersist
    void onCreate() {
        if (clickDt == null) clickDt = OffsetDateTime.now(); // 자바 시간으로 기록
    }
}