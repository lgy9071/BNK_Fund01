package com.example.common.entity.admin;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Entity
@Table(name = "approval_log")
@Getter
@Setter
public class ApprovalLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer logId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "approval_id")
    private Approval approval;

    private String changerId;

    private String status;

    @Column(columnDefinition = "TEXT")
    private String reason;

    private LocalDateTime changedAt = LocalDateTime.now();
}