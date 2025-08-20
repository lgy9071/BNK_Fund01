package com.example.fund.otp.store;

import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class OtpStore {
    public static record Entry(String code, Instant expiresAt, int attempts) {}

    // key: email
    private final Map<String, Entry> store = new ConcurrentHashMap<>();
    private final long ttlSeconds = 180; // 3분

    public void put(String email, String code) {
        store.put(email, new Entry(code, Instant.now().plusSeconds(ttlSeconds), 0));
    }

    public Entry get(String email) {
        var e = store.get(email);
        if (e == null) return null;
        if (Instant.now().isAfter(e.expiresAt())) { // 만료
            store.remove(email);
            return null;
        }
        return e;
    }

    public void incrementAttempts(String email) {
        var e = store.get(email);
        if (e != null) store.put(email, new Entry(e.code(), e.expiresAt(), e.attempts()+1));
    }

    public void remove(String email) { store.remove(email); }
}