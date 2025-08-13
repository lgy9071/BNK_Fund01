package com.example.common.entity.admin;

import com.example.common.entity.fund.BaseEntity;
import com.example.common.entity.fund.Fund;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "tbl_approval")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Approval extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer approvalId;

    @Column(length = 100, nullable = false)
    private String title;

    @Column(length = 100, nullable = false)
    private String content;

    @ManyToOne
    @JoinColumn(name = "writer_id", referencedColumnName = "admin_id")
    private Admin writer;

    @Column(length = 20, nullable = false)
    private String status;

    @Column(length = 200)
    private String rejectReason; // 반려 사유

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id")
    private Fund fund;
}
