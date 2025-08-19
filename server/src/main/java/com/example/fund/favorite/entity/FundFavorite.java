package com.example.fund.favorite.entity;

import com.example.fund.fund.entity_fund.Fund;
import com.example.fund.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity
@Table(name = "tbl_fund_favorite",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "fund_id"}))
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class FundFavorite {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long favoriteId;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "fund_id")
    private Fund fund;

    @CreationTimestamp
    private LocalDateTime createdAt;
}
