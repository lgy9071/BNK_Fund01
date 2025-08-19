package com.example.fund.account.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;

@Entity
@Table(
    name = "branch",
    indexes = {
        @Index(name = "idx_branch_name", columnList = "branch_name")
    },
    uniqueConstraints = {
        @UniqueConstraint(name = "uk_branch_name_addr", columnNames = {"branch_name", "address"})
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@SequenceGenerator(
    name = "branch_seq_generator",
    sequenceName = "branch_seq",   // 오라클 시퀀스명
    allocationSize = 1             // 갭 방지용 1 권장
)
public class Branch {

    /** 영업점 고유 ID (PK) — 오라클 시퀀스 사용 */
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "branch_seq_generator")
    @Column(name = "branch_id", nullable = false, updatable = false)
    private Long branchId;

    /** 지점명 (NOT NULL, VARCHAR2(100)) */
    @Column(name = "branch_name", nullable = false, length = 100)
    private String branchName;

    /** 지점 도로명 주소 (NOT NULL, VARCHAR2(255)) */
    @Column(name = "address", nullable = false, length = 255)
    private String address;

    /** 위도 (NUMBER(9,6), NOT NULL) */
    @Column(name = "lat", nullable = false, precision = 9, scale = 6)
    private BigDecimal lat;

    /** 경도 (NUMBER(9,6), NOT NULL) */
    @Column(name = "lng", nullable = false, precision = 9, scale = 6)
    private BigDecimal lng;
}
