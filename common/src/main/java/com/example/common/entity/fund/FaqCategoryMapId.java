package com.example.common.entity.fund;

import lombok.*;

import java.io.Serializable;

@Getter
@Setter
@EqualsAndHashCode
@NoArgsConstructor
@AllArgsConstructor
public class FaqCategoryMapId implements Serializable {
    private Integer faqId;
    private String category;
}