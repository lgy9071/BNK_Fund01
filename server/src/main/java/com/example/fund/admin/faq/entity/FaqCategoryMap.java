package com.example.fund.admin.faq.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import lombok.*;

@Entity
@IdClass(FaqCategoryMapId.class) // 복합키( faqId + category )를 IdClass로 사용
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FaqCategoryMap {

    /**
     * FAQ ID (Faq 테이블의 PK)
     * - 이 컬럼과 category 컬럼을 함께 복합 PK로 사용
     */
    @Id
    private Integer faqId;

    /**
     * 카테고리명
     * - faqId와 함께 복합 PK 구성 요소
     */
    @Id
    private String category;
}
