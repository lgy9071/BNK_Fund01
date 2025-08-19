package com.example.fund.fund.entity_fund_etc;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "fund_holding")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FundHolding {

    @Id @GeneratedValue
    private Long holdingId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id")
    private Fund fund;

    private int quantity;
    private int avgPrice;
    private LocalDateTime joinedAt;
}
