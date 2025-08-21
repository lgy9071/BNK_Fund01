package com.example.fund.fund.entity_fund_etc;

import com.example.fund.common.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "fund_status")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundStatus extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "status_id")
    private Integer statusId;

    @Column(name = "category", length = 10, nullable = false)
    private String category; // 국내 or 해외

    @Column(name = "title", length = 50, nullable = false)
    private String title;

    @Column(length = 3000)
    private String content;

    @Column(name = "view_count", nullable = false)
    private Integer viewCount = 0;
}
