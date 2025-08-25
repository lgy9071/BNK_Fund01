package com.example.fund.account.service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fund.account.dto.BranchDistanceDto;
import com.example.fund.account.entity.Branch;
import com.example.fund.account.geocode.Coords;         // ✅ 반드시 이 Coords를 import
import com.example.fund.account.geocode.GeocodeService;
import com.example.fund.account.repository.BranchRepository;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Service
@RequiredArgsConstructor
@Slf4j
public class NearbyBranchService {

    private final BranchRepository branchRepository;

    // ⚠ 실제 GeocodeService 빈 이름이 'legacyGeocodeService'가 아니라면 @Qualifier 제거
    private final @Qualifier("legacyGeocodeService") GeocodeService geocodeService;

    // 주소별 좌표 캐시(런타임)
    private final Map<String, Coords> cache = new ConcurrentHashMap<>();

    /**
     * 반경 내 지점 조회 (미지오코딩 지점은 즉석 지오코딩 후 DB에 백필)
     */
    @Transactional
    public List<BranchDistanceDto> findWithinRadius(double myLat, double myLng, double radiusMeters) {
        List<Branch> all = branchRepository.findAll();
        List<BranchDistanceDto> out = new ArrayList<>(Math.max(16, all.size()));

        for (Branch b : all) {
            Coords coords = resolveLatLngAndBackfill(b);
            if (coords == null) {
                log.info("SKIP(no coord): id={}, name={}, addr={}",
                        b.getBranchId(), b.getBranchName(), b.getAddress());
                continue;
            }

            double dist = haversineMeters(myLat, myLng, coords.lat(), coords.lng());
            if (dist <= radiusMeters) {
                out.add(BranchDistanceDto.builder()
                        .branchId(b.getBranchId())
                        .branchName(b.getBranchName())
                        .address(b.getAddress())
                        .lat(coords.lat())
                        .lng(coords.lng())
                        .distanceMeters(dist)
                        .build());
            }
        }

        out.sort(Comparator.comparingDouble(BranchDistanceDto::getDistanceMeters));
        log.info("✅ Nearby result count={}", out.size());
        return out;
    }

    /** 좌표 확인 → 없으면 지오코딩 → 성공 시 DB 백필 + 캐시 저장 */
    private Coords resolveLatLngAndBackfill(Branch b) {
        Double lat = b.getLat();
        Double lng = b.getLng();

        if (isValid(lat, lng)) {
            return new Coords(lat, lng); // DB 좌표 사용
        }

        String addr = normalizeAddress(b.getAddress());
        if (addr == null || addr.isBlank()) return null;

        // 캐시 조회
        Coords cached = cache.get(addr);
        if (cached != null && isValid(cached.lat(), cached.lng())) {
            persistIfEmpty(b, cached); // DB 비었으면 백필
            return cached;
        }

        log.info("GEOCODE try: id={}, name={}, addr='{}'", b.getBranchId(), b.getBranchName(), addr);
        return geocodeService.geocode(addr).map(v -> {
            cache.put(addr, v);
            persistIfEmpty(b, v);
            log.info("GEOCODE OK: id={}, lat={}, lng={}", b.getBranchId(), v.lat(), v.lng());
            return v;
        }).orElseGet(() -> {
            log.warn("GEOCODE FAIL: id={}, addr='{}'", b.getBranchId(), addr);
            return null;
        });
    }

    /** DB lat/lng가 비어 있으면 백필 저장 */
    private void persistIfEmpty(Branch b, Coords c) {
        if (!isValid(b.getLat(), b.getLng())) {
            try {
                b.setLat(c.lat());
                b.setLng(c.lng());
                branchRepository.save(b);
            } catch (Exception e) {
                log.warn("Backfill save failed: id={}, err={}", b.getBranchId(), e.toString());
            }
        }
    }

    private static boolean isValid(Double lat, Double lng) {
        if (lat == null || lng == null) return false;
        if (lat == 0.0 && lng == 0.0) return false;
        return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
    }

    private String normalizeAddress(String raw) {
        if (raw == null) return null;
        // (반여동) 같은 괄호 제거, 다중 공백 정리
        String s = raw.replaceAll("\\(.*?\\)", " ");
        s = s.replaceAll("\\s+", " ").trim();
        return s;
    }

    private static double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        final double R = 6_371_000.0; // m
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
