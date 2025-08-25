package com.example.fund.account.service;

import java.nio.charset.StandardCharsets;
import java.util.Optional;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

@Service
@RequiredArgsConstructor
@Slf4j
public class GeocodeService {

    @Value("${naver.geocode.key-id}")   String keyId;
    @Value("${naver.geocode.secret}")   String secret;
    @Value("${naver.geocode.base-url}") String baseUrl;

    private final RestTemplate rest = new RestTemplate();

    @PostConstruct
    void checkKeys() {
        log.info("NAVER key loaded? keyId={}..., secret?={}",
                keyId != null && keyId.length() >= 4 ? keyId.substring(0,4) : "NULL",
                secret != null && !secret.isBlank());
    }

    public Optional<double[]> geocode(String rawAddress) {
        // (선택) 괄호 안 보조 표기는 지오코딩 정확도를 떨어뜨릴 수 있어 제거
        String address = rawAddress == null ? "" :
                rawAddress.replaceAll("\\s*\\([^)]*\\)\\s*", " ").trim();

        try {
            String url = UriComponentsBuilder
                    .fromHttpUrl(baseUrl)              // ex) https://naveropenapi.apigw.ntruss.com/map-geocode/v2/geocode
                    .queryParam("query", address)      // 한글 그대로 전달
                    .build()                           // ✅ build(true) 금지
                    .encode(StandardCharsets.UTF_8)    // ✅ 여기서 UTF-8 인코딩
                    .toUriString();

            HttpHeaders headers = new HttpHeaders();
            headers.add("X-NCP-APIGW-API-KEY-ID", keyId);
            headers.add("X-NCP-APIGW-API-KEY",    secret);

            ResponseEntity<NaverGeocodeResponse> res = rest.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), NaverGeocodeResponse.class);

            log.info("GEOCODE HTTP status={} for '{}'", res.getStatusCode(), address);

            NaverGeocodeResponse body = res.getBody();
            if (body == null || body.addresses() == null || body.addresses().isEmpty()) {
                return Optional.empty();
            }

            var item = body.addresses().get(0);
            // 네이버는 x=lng, y=lat
            double lat = Double.parseDouble(item.y());
            double lng = Double.parseDouble(item.x());
            return Optional.of(new double[]{ lat, lng });
        } catch (Exception e) {
            log.warn("GEOCODE EX for '{}': {}", address, e.toString());
            return Optional.empty();
        }
    }

    public record NaverGeocodeResponse(java.util.List<Item> addresses) {
        public record Item(String x, String y, String roadAddress, String jibunAddress) {}
    }
}
