package com.example.batch_scraper.entity;

import java.math.BigDecimal;
import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

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