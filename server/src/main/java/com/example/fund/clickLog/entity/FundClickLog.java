package com.example.fund.clickLog.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "FUND_CLICK_LOG")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
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

    // DB 기본값 사용 → insertable=false 로 두어도 됨
    @Column(name = "CLICK_DT", insertable = false, updatable = false)
    private java.time.OffsetDateTime clickDt;
}