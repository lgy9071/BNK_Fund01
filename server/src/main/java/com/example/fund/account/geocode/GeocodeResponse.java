package com.example.fund.account.geocode;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.Data;

import java.util.List;

/**
 * Naver Geocoding 응답 DTO (필요 필드만)
 * 참고: https://api.ncloud-docs.com/docs/ai-naver-mapsgeocoding-geocode
 */
@Data
@JsonIgnoreProperties(ignoreUnknown = true)
public class GeocodeResponse {
    private String status;              // "OK" 등
    private Meta meta;                  // totalCount 등
    private List<Address> addresses;    // 결과 목록
    private String errorMessage;        // 에러 메시지(있을 경우)

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Meta {
        private Integer totalCount;
        private Integer page;
        private Integer count;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class Address {
        private String roadAddress;     // 도로명 주소
        private String jibunAddress;    // 지번 주소
        private String englishAddress;

        private String x;               // 경도(lng) - 문자열
        private String y;               // 위도(lat) - 문자열
        private Double distance;        // 거리(옵션)

        private List<AddressElement> addressElements;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class AddressElement {
        private List<String> types;
        private String longName;
        private String shortName;
        private String code;
    }
}
