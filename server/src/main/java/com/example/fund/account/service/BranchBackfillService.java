// src/main/java/com/example/fund/account/service/BranchBackfillService.java
package com.example.fund.account.service;

import com.example.fund.account.entity.Branch;
import com.example.fund.account.repository.BranchRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Slf4j
@Service
@RequiredArgsConstructor
public class BranchBackfillService {

    private final BranchRepository repo;
    private final GeocodeService geocode; // 네이버 지오코딩 (이미 만드신 그 서비스)

    @PersistenceContext
    private EntityManager em;

    // 네이버 QPS 보호(기본 200ms) — application.properties 에서 오버라이드 가능
    @Value("${naver.geocode.min-interval-ms:200}")
    private int minIntervalMs;

    // 같은 주소 반복 지오코딩 방지
    private final Map<String, double[]> cache = new ConcurrentHashMap<>();

    /**
     * 주소만 있는 Branch 들의 lat/lng 를 채운다.
     * @param limit   최대 갱신 건수(0 또는 음수면 무제한)
     * @param pageSize 페이지 단위 처리(200 권장)
     * @param dryRun  true면 저장하지 않고 로그만
     * @return 실제 갱신 성공 건수
     */
    @Transactional
    public int backfillLatLng(int limit, int pageSize, boolean dryRun) {
        int updated = 0;
        int page = 0;

     // BranchBackfillService.java (일부)
        while (true) {
            Page<Branch> targets =
                repo.findByLatIsNullOrLngIsNullOrLatEqualsAndLngEquals(0.0, 0.0, PageRequest.of(page, pageSize));
            if (targets.isEmpty()) break;

            for (Branch b : targets.getContent()) {
                // 주소 정규화
                String addr = AddressNormalizer.normalize(b.getAddress());
                if (addr == null || addr.isBlank()) { /* skip 로그 */ continue; }

                double[] latlng = cache.get(addr);
                if (latlng == null) {
                    sleep(minIntervalMs);
                    latlng = geocode.geocode(addr).orElse(null);
                    if (latlng != null) cache.put(addr, latlng);
                }
                if (latlng == null) { /* geocode 실패 로그 */ continue; }

                if (!dryRun) {
                    b.setLat(latlng[0]); // y=lat
                    b.setLng(latlng[1]); // x=lng
                }
                updated++;
                if (!dryRun && (updated % 50 == 0)) { em.flush(); em.clear(); }
            }
            page++;
        }
        if (!dryRun) { em.flush(); em.clear(); }

        log.info("Backfill 완료. updated={}", updated);
        return updated;
    }

    private void sleep(long ms) {
        try { Thread.sleep(ms); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
    }
}
