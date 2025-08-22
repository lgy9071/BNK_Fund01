package com.example.fund.holiday;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class HolidayService {
    private final RestClient client;
    private final HolidayApiProps props;

    public HolidayService(RestClient holidayRestClient, HolidayApiProps props) {
        this.client = holidayRestClient;
        this.props = props;
    }

    /** 해당 연/월의 공휴일+대체공휴일 날짜 집합 */
    public Set<LocalDate> getHolidays(int year, int month) {
        String url = UriComponentsBuilder.fromPath("/getRestDeInfo")
                .queryParam("ServiceKey", props.serviceKey())   // Encoding 키
                .queryParam("_type", "json")
                .queryParam("solYear", year)
                .queryParam("solMonth", String.format("%02d", month))
                .build().toUriString();

        HolidayResponse res = client.get().uri(url).retrieve().body(HolidayResponse.class);

        List<HolidayResponse.Item> items =
                res != null &&
                res.response() != null &&
                res.response().body() != null &&
                res.response().body().items() != null &&
                res.response().body().items().item() != null
                        ? res.response().body().items().item()
                        : List.of();

        Set<LocalDate> set = new HashSet<>();
        for (var it : items) {
            if (it != null && "Y".equalsIgnoreCase(it.isHoliday())) {
                String yyyymmdd = String.valueOf(it.locdate()); // e.g. 20250101
                LocalDate d = LocalDate.of(
                        Integer.parseInt(yyyymmdd.substring(0, 4)),
                        Integer.parseInt(yyyymmdd.substring(4, 6)),
                        Integer.parseInt(yyyymmdd.substring(6, 8))
                );
                set.add(d);
            }
        }
        return set;
    }
    // 영업일 여부
    public boolean isBusinessDay(LocalDate d) {
        return !isWeekend(d) && !isHoliday(d);
    }

    // d가 영업일이 아니면 '해당 날짜 또는 이후'의 첫 영업일로 보정
    public LocalDate normalizeToBusinessDay(LocalDate d) {
	     LocalDate x = d;
	     while (!isBusinessDay(x)) x = x.plusDays(1);
	     return x; // d가 영업일이면 d 그대로 반환
	 }

    public boolean isWeekend(LocalDate d) {
        int dow = d.getDayOfWeek().getValue(); // 1=Mon ... 7=Sun
        return dow >= 6;
    }

    public boolean isHoliday(LocalDate d) {
        return getHolidays(d.getYear(), d.getMonthValue()).contains(d);
    }

    /** 주말/공휴일 제외 다음 영업일 */
    public LocalDate nextBusinessDay(LocalDate d) {
        while (isWeekend(d) || isHoliday(d)) d = d.plusDays(1);
        return d;
    }
 // 영업일 N일 가산 (startExclusive 이후부터 N영업일)
    public LocalDate addBusinessDays(LocalDate startExclusive, int n) {
        LocalDate x = startExclusive;
        for (int i = 0; i < n; i++) x = nextBusinessDay(x);
        return x;
    }
}
