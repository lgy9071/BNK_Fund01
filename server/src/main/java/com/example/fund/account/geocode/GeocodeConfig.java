package com.example.fund.account.geocode;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

@Configuration("geocodeConfig") // 로그에 나온 빈 이름과 맞춤 (선택: 안 맞춰도 동작함)
public class GeocodeConfig {

    // 기본 URL은 프로퍼티 없으면 디폴트 사용
    @Value("${naver.api.base-url:https://naveropenapi.apigw.ntruss.com}")
    private String baseUrl;

    // 1순위: application.properties 의 naver.api.key-id
    // 2순위: 환경변수 NAVER_KEY_ID
    // 3순위: 빈 문자열 (부팅은 되게)
    @Value("${naver.api.key-id:${NAVER_KEY_ID:}}")
    private String keyId;

    @Value("${naver.api.key:${NAVER_KEY:}}")
    private String key;

    @Value("${naver.api.timeout-ms:7000}")
    private int timeoutMs;

    @Bean("geocodeRestClient")
    public RestClient geocodeRestClient(RestClient.Builder builder) {
        SimpleClientHttpRequestFactory rf = new SimpleClientHttpRequestFactory();
        rf.setConnectTimeout(timeoutMs);
        rf.setReadTimeout(timeoutMs);

        return builder
            .baseUrl(baseUrl)
            .requestFactory(rf)
            .defaultHeaders(h -> {
                // Naver API Gateway headers
                h.set("X-NCP-APIGW-API-KEY-ID", keyId);
                h.set("X-NCP-APIGW-API-KEY", key);
            })
            .build();
    }
}
