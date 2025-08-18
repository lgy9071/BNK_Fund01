package com.example.fund.account.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "branch")
@Getter @Setter
@NoArgsConstructor @AllArgsConstructor @Builder
public class Branch {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // Oracle 12c+
    @Column(name = "branch_id", nullable = false)
    private Long branchId;                 // 지점 ID (AUTO_INCREMENT)

    @Column(name = "branch_name", length = 50)
    private String branchName;             // 지점명

    @Lob
    @Column(name = "address", columnDefinition = "CLOB")
    private String address;                // 지점 주소(도로명) - TEXT -> CLOB
}
