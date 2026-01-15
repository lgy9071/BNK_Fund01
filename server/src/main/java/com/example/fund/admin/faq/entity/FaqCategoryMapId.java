package com.example.fund.admin.faq.entity;

import lombok.*;

import java.io.Serializable;

@Getter
@Setter
@EqualsAndHashCode // 복합키 비교를 위해 필수
@NoArgsConstructor
@AllArgsConstructor
public class FaqCategoryMapId implements Serializable {

    // FAQ 기본키
    private Integer faqId;

    // 카테고리명
    private String category;
}
