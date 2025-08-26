package com.example.fund.admin.service;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;

import org.springframework.dao.DataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.example.fund.admin.repository.UserSearchRepository;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class CustomerService {

    private final UserSearchRepository repo;

    private static final Pattern DIGITS = Pattern.compile("\\d+");

    /* =========================
       1) 검색: 이름/이메일/전화 (한 줄 리스트용)
       ========================= */
    public List<ListItem> search(String q) {
        if (q == null || q.isBlank()) return List.of();

        final String qLower = q.toLowerCase();
        final String onlyDigits = q.replaceAll("\\D", "");
        final boolean digits11 = onlyDigits.length() == 11 && DIGITS.matcher(onlyDigits).matches();
        final String hyphen = digits11 ? hyphen114(onlyDigits) : null;

        return repo.searchList(
                    qLower,
                    onlyDigits.isEmpty() ? null : onlyDigits,
                    hyphen
               ).stream()
               .map(r -> new ListItem(
                       r.getUserId(),
                       nvl(r.getName(), "-"),
                       nvl(r.getEmail(), "-"),
                       formatPhone(r.getPhone())
               ))
               .toList();
    }

    /** 상세: 기본 정보 + (펀드 집계는 없으면 건너뜀) */
    @Transactional(readOnly = true, propagation = Propagation.NOT_SUPPORTED) // 트랜잭션 사용 안 함
    public Detail getDetail(Long userId){
        var u = repo.findDetail(userId);
        if (u == null) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "고객이 없습니다.");

        List<UserSearchRepository.UserFundAggRow> agg = List.of(); // 기본은 빈 목록
        try {
            agg = repo.findUserFundAgg(userId); // FUND_TRANSACTION 없어도 try-catch로 흡수
        } catch (DataAccessException ex) {
            // log.warn("펀드 집계 스킵: {}", ex.getMessage());
        }

        var funds = agg.stream()
                .map(a -> new FundDto(
                        a.getFundId(),
                        nvl(a.getFundName(), "-"),
                        toLong(a.getNetAmount()),
                        toLocalDate(a.getFirstSubscribedAt())
                ))
                .toList();

        long totalAsset = agg.stream()
                .map(UserSearchRepository.UserFundAggRow::getNetAmount)
                .filter(Objects::nonNull)
                .mapToLong(CustomerService::toLong)
                .sum();

        LocalDate firstSubscribedAt = agg.stream()
                .map(UserSearchRepository.UserFundAggRow::getFirstSubscribedAt)
                .filter(Objects::nonNull)
                .map(CustomerService::toLocalDate)
                .min(Comparator.naturalOrder())
                .orElse(null);

        return new Detail(
                u.getUserId(),
                nvl(u.getName(), "-"),
                nvl(u.getEmail(), "-"),
                formatPhone(u.getPhone()),
                nvl(u.getUsername(), "-"),
                funds,
                totalAsset,
                firstSubscribedAt
        );
    }

    /* =========================
       helpers & DTOs
       ========================= */
    private static String hyphen114(String d){ return d.substring(0,3)+"-"+d.substring(3,7)+"-"+d.substring(7); }

    // 화면 표시용 전화번호
    private static String formatPhone(String raw){
        if (raw == null || raw.isBlank()) return "-";
        String d = raw.replaceAll("\\D","");
        return d.length()==11 ? hyphen114(d) : raw;
    }

    private static String nvl(String v, String def){ return (v==null || v.isBlank()) ? def : v; }
    private static long toLong(BigDecimal v){ return v==null?0L:v.longValue(); }
    private static LocalDate toLocalDate(Timestamp ts){ return ts==null?null:ts.toLocalDateTime().toLocalDate(); }

    /** 검색 리스트용 최소 응답 */
    public record ListItem(Long id, String name, String email, String phone) {}

    /** 상세 내 펀드 항목 */
    public record FundDto(Long fundId, String name, Long assetAmount, LocalDate firstSubscribedAt) {}

    /** 상세 전체 응답 */
    public record Detail(
            Long id,
            String name,
            String email,
            String phone,
            String username,
            List<FundDto> funds,
            Long totalAssetAmount,
            LocalDate firstSubscribedAt
    ) {}
}
