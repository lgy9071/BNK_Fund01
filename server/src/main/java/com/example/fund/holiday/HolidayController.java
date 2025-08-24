package com.example.fund.holiday;

import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;
import java.util.Set;

@RestController
@RequestMapping("/api/holidays")
public class HolidayController {
    private final HolidayService svc;
    public HolidayController(HolidayService svc) { this.svc = svc; }

    // 예: GET /api/holidays/2025/8
    @GetMapping("/{year}/{month}")
    public Set<LocalDate> list(@PathVariable int year, @PathVariable int month) {
        return svc.getHolidays(year, month);
    }

    // 예: GET /api/holidays/next-biz?date=2025-08-22
    @GetMapping("/next-biz")
    public Map<String, Object> nextBiz(@RequestParam String date) {
        LocalDate d = LocalDate.parse(date);
        return Map.of(
                "input", d,
                "nextBusinessDay", svc.nextBusinessDay(d)
        );
    }
}
