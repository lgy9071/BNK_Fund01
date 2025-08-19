package com.example.fund.account.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "branch")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Branch {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Oracle 12c+
    @Column(name = "branch_id", nullable = false)
    private Integer branchId;                 // 지점 ID (AUTO_INCREMENT)

    @Column(name = "branch_name", length = 50)
    private String branchName;             // 지점명

    @Lob
    @Column(name = "address", columnDefinition = "CLOB")
    private String address;                // 지점 주소(도로명) - TEXT -> CLOB
}
