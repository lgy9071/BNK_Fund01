package com.example.fund.account.geocode;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service("legacyGeocodeService")
@RequiredArgsConstructor
public class GeocodeService {

    private final RestClient geocodeRestClient;

    // 부산을 기본 바이어스(지오코딩 후보를 부산/울산 인근으로 유도)
    @Value("${geocode.bias.lat:35.1796}")
    private double biasLat;

    @Value("${geocode.bias.lng:129.0756}")
    private double biasLng;

    // 간단 캐시 (동일 주소 중복 호출 방지)
    private final Map<String, Coords> cache = new ConcurrentHashMap<>();

    /**
     * 주소 → 좌표 (Optional)
     * 성공 시 (lat, lng) 반환. 실패 시 Optional.empty()
     */
    public Optional<Coords> geocode(String rawAddress) {
        String normalized = normalize(rawAddress);
        if (normalized == null || normalized.isBlank()) {
            return Optional.empty();
        }

        // 캐시 히트
        Coords cached = cache.get(normalized);
        if (cached != null) return Optional.of(cached);

        String uri = UriComponentsBuilder.fromPath("/map-geocode/v2/geocode")
                .queryParam("query", normalized)
                // Naver: coordinate는 "x,y" = "lng,lat" 순서
                .queryParam("coordinate", biasLng + "," + biasLat)
                .toUriString();

        try {
            GeocodeResponse res = geocodeRestClient.get()
                    .uri(uri)
                    .retrieve()
                    .body(GeocodeResponse.class);

            if (res == null || res.getAddresses() == null || res.getAddresses().isEmpty()) {
                log.info("GEOCODE no result for '{}'", normalized);
                return Optional.empty();
            }

            GeocodeResponse.Address a = res.getAddresses().get(0);
            // Naver 응답: x=lng, y=lat (문자열)
            double lat = Double.parseDouble(a.getY());
            double lng = Double.parseDouble(a.getX());

            Coords coords = new Coords(lat, lng);
            cache.put(normalized, coords);
            return Optional.of(coords);

        } catch (HttpClientErrorException | HttpServerErrorException e) {
            // 여기서 응답 본문(body)을 안전하게 확인 가능
            String body = e.getResponseBodyAsString();
            log.warn("GEOCODE {} for '{}': status={}, body={}",
                    e.getClass().getSimpleName(), normalized, e.getStatusCode(), body);
            return Optional.empty();

        } catch (RestClientException e) {
            log.warn("GEOCODE EX for '{}': {}", normalized, e.toString());
            return Optional.empty();
        }
    }

    /**
     * 주소 정규화: 괄호(동/리) 제거, 다중 공백 축소,
     * '금샘로485' → '금샘로 485' 같은 붙어쓴 도로명 번호를 분리
     */
    static String normalize(String raw) {
        if (raw == null) return null;
        String s = raw
                .replaceAll("\\s*\\([^)]*\\)\\s*", " ") // 괄호 제거
                .replaceAll("\\s+", " ")               // 다중 공백 → 단일 공백
                .trim();

        // 도로명 뒤에 붙은 숫자 분리
        s = s.replaceAll("([가-힣A-Za-z]+로)(\\d)", "$1 $2");
        s = s.replaceAll("([가-힣A-Za-z]+길)(\\d)", "$1 $2");
        s = s.replaceAll("([가-힣A-Za-z]+대로)(\\d)", "$1 $2");
        return s;
    }
}


