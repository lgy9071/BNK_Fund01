package com.example.fund.account.entity;

import java.math.BigDecimal;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "transit_account")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class TransitAccount {

    @Id
    @Column(name = "transit_account_id", nullable = false)
    private Integer transitAccountId; // 항상 1로 운용(싱글톤) 권장

    @Column(name = "transit_account_number", length = 30, unique = true)
    private String transitAccountNumber; // UNIQUE

    @Column(name = "balance", precision = 18, scale = 0)
    private BigDecimal balance;
}
