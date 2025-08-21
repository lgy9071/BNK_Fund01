package com.example.fund.api.common;

public final class UrlSafe {
    private UrlSafe() {}

    /** 문자열 안의 대괄호만 URL 인코딩([ → %5B, ] → %5D) 합니다. */
    public static String encodeSquareBrackets(String input) {
        if (input == null || input.isEmpty()) return input;
        StringBuilder sb = new StringBuilder(input.length());
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            if (c == '[')      sb.append("%5B");
            else if (c == ']') sb.append("%5D");
            else               sb.append(c);
        }
        return sb.toString();
    }
}