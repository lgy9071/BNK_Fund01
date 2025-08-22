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
}
