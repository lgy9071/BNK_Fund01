package com.example.fund.admin.faq.repository.projection;

public interface FaqCategoryCount {

    // 카테고리명 반환
    String getCategory();

    // 해당 카테고리 FAQ 개수 반환
    Long getCnt();
}
