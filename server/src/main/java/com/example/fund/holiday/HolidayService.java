package com.example.fund.holiday;

import java.time.LocalDate;
import java.util.HashSet;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.util.UriComponentsBuilder;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class HolidayService {
    private final RestClient client;
    private final HolidayApiProps props;

    public HolidayService(RestClient holidayRestClient, HolidayApiProps props) {
        this.client = holidayRestClient;
        this.props = props;
    }

    /** 해당 연/월의 공휴일+대체공휴일 날짜 집합 */
 // 파일 상단 클래스 안 어딘가에 추가(중복 없게)
    private static final ObjectMapper JSON = new ObjectMapper();
    private static final Pattern ITEM = Pattern.compile("<item>(.*?)</item>", Pattern.DOTALL);
    private static final Pattern XML_IS_HOLIDAY = Pattern.compile("<isHoliday>([YN])</isHoliday>");
    private static final Pattern XML_LOCDATE   = Pattern.compile("<locdate>(\\d{8})</locdate>");

    /** 해당 연/월의 공휴일+대체공휴일 날짜 집합 */
    public Set<LocalDate> getHolidays(int year, int month) {
        String url = UriComponentsBuilder.fromPath("/getRestDeInfo")
                // 핵심 1) serviceKey 소문자 권장 (공공데이터 일부 엔드포인트는 소문자만 JSON 인식)
                .queryParam("serviceKey", props.serviceKey())
                .queryParam("_type", "json")
                .queryParam("solYear", year)
                .queryParam("solMonth", String.format("%02d", month))
                .build()
                .toUriString();

        // 핵심 2) 먼저 문자열로 받아서(JSON/XML) 판별
        String body = client.get()
                .uri(url)
                .accept(MediaType.APPLICATION_JSON, MediaType.APPLICATION_XML, MediaType.TEXT_XML)
                .retrieve()
                .body(String.class);

        Set<LocalDate> set = new HashSet<>();
        if (body == null || body.isBlank()) return set;

        String s = body.stripLeading();

        // ── JSON 응답일 때
        if (s.startsWith("{")) {
            try {
                JsonNode root = JSON.readTree(s);
                JsonNode items = root.path("response").path("body").path("items").path("item");

                // item이 배열일 수도, 단일 객체일 수도 있음
                if (items.isArray()) {
                    for (JsonNode it : items) {
                        addIfHolidayFromJsonNode(it, set);
                    }
                } else if (items.isObject()) {
                    addIfHolidayFromJsonNode(items, set);
                }
                return set;
            } catch (Exception ignore) {
                // JSON 파싱 실패 시 XML fallback로 계속 진행
            }
        }

        // ── XML 응답일 때(일부 케이스: 키 오류/서버 버그 등으로 _type=json 무시)
        Matcher m = ITEM.matcher(s);
        while (m.find()) {
            String itemXml = m.group(1);
            Matcher h = XML_IS_HOLIDAY.matcher(itemXml);
            Matcher l = XML_LOCDATE.matcher(itemXml);
            if (h.find() && "Y".equalsIgnoreCase(h.group(1)) && l.find()) {
                String yyyymmdd = l.group(1);
                set.add(LocalDate.of(
                        Integer.parseInt(yyyymmdd.substring(0, 4)),
                        Integer.parseInt(yyyymmdd.substring(4, 6)),
                        Integer.parseInt(yyyymmdd.substring(6, 8))
                ));
            }
        }
        return set;
    }

    // JSON item 하나 처리 헬퍼(동일 파일 안에 private 메서드로 추가)
    private void addIfHolidayFromJsonNode(JsonNode it, Set<LocalDate> out) {
        if (!"Y".equalsIgnoreCase(it.path("isHoliday").asText())) return;
        String yyyymmdd = it.path("locdate").asText(null);
        if (yyyymmdd == null || yyyymmdd.length() != 8) return;
        out.add(LocalDate.of(
                Integer.parseInt(yyyymmdd.substring(0, 4)),
                Integer.parseInt(yyyymmdd.substring(4, 6)),
                Integer.parseInt(yyyymmdd.substring(6, 8))
        ));
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
        LocalDate x = d.plusDays(1);               // ✅ 익일부터 검사
        while (isWeekend(x) || isHoliday(x)) {
            x = x.plusDays(1);
        }
        return x;
    }
 // 영업일 N일 가산 (startExclusive 이후부터 N영업일)
    public LocalDate addBusinessDays(LocalDate startExclusive, int n) {
        LocalDate x = startExclusive;
        for (int i = 0; i < n; i++) x = nextBusinessDay(x);
        return x;
    }
}
