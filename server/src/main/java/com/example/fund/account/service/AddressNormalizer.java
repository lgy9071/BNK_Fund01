// src/main/java/com/example/fund/account/service/AddressNormalizer.java
package com.example.fund.account.service;

public class AddressNormalizer {
    private AddressNormalizer() {}

    /** 예: "부산광역시 해운대구 (좌동) 세실로 10" -> "부산광역시 해운대구  세실로 10" */
    public static String normalize(String raw) {
        if (raw == null) return null;
        String s = raw.replaceAll("\\(.*?\\)", ""); // 괄호 내용 제거
        s = s.replaceAll("\\s+", " ").trim();       // 중복 공백 정리
        return s;
    }
}
