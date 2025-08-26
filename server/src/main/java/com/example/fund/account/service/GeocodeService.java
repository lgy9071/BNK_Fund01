package com.example.fund.account.service;

import java.nio.charset.StandardCharsets;
import java.util.Optional;
import java.util.List;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class GeocodeService {

    private final RestClient client;     // GeocodeConfig에서 만든 빈 사용
    private final String baseUrl;
    private final String keyId;
    private final String secret;

    // ✅ 생성자 "파라미터"에 @Qualifier로 명시 (가장 확실)
    public GeocodeService(
            @Qualifier("geocodeRestClient") RestClient client,
            @Value("${naver.geocode.base-url}") String baseUrl,
            @Value("${naver.geocode.key-id}")   String keyId,
            @Value("${naver.geocode.secret}")   String secret
    ) {
        this.client = client;
        this.baseUrl = baseUrl;
        this.keyId = keyId;
        this.secret = secret;
    }

    @PostConstruct
    void checkKeys() {
        log.info("NAVER key loaded? keyId={}..., secret?={}",
                keyId != null && keyId.length() >= 4 ? keyId.substring(0,4) : "NULL",
                secret != null && !secret.isBlank());
    }

    public Optional<double[]> geocode(String rawAddress) {
        // (선택) 괄호 안 보조 표기는 지오코딩 정확도 저해 가능 → 제거
        String address = rawAddress == null ? "" :
                rawAddress.replaceAll("\\s*\\([^)]*\\)\\s*", " ").trim();

        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(baseUrl)           // ex) https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode
                    .queryParam("query", address)   // 한글 그대로 전달
                    .build()                        // build(true) 금지
                    .encode(StandardCharsets.UTF_8) // 여기서 UTF-8 인코딩
                    .toUriString();

            // GeocodeConfig에서 RestClient 기본 헤더(X-NCP-APIGW-API-KEY-*)를 이미 세팅했다고 가정
            NaverGeocodeResponse body = client.get()
                    .uri(url)
                    .retrieve()
                    .body(NaverGeocodeResponse.class);

            if (body == null || body.addresses() == null || body.addresses().isEmpty()) {
                return Optional.empty();
            }

            var item = body.addresses().get(0);
            // 네이버는 x=경도(lng), y=위도(lat)
            double lat = Double.parseDouble(item.y());
            double lng = Double.parseDouble(item.x());
            return Optional.of(new double[]{ lat, lng });

        } catch (Exception e) {
            log.warn("GEOCODE EX for '{}': {}", address, e.toString());
            return Optional.empty();
        }
    }

    public record NaverGeocodeResponse(List<Item> addresses) {
        public record Item(String x, String y, String roadAddress, String jibunAddress) {}
    }
}
