package com.example.fund.fund.entity_fund;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "fund_bond_types")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FundBondTypes {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "fund_bond_types_id")
    private Long fundBondTypesId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "fund_id", referencedColumnName = "fund_id", nullable = false)
    private Fund fund;

    @Column(name = "base_date", nullable = false)
    private LocalDate baseDate;

    @Column(name = "gov_bond_ratio", precision = 5, scale = 2)
    private BigDecimal govBondRatio;

    @Column(name = "moa_bond_ratio", precision = 5, scale = 2)
    private BigDecimal moaBondRatio;

    @Column(name = "fin_bond_ratio", precision = 5, scale = 2)
    private BigDecimal finBondRatio;

    @Column(name = "corp_bond_ratio", precision = 5, scale = 2)
    private BigDecimal corpBondRatio;

    @Column(name = "other_ratio", precision = 5, scale = 2)
    private BigDecimal otherRatio;
}