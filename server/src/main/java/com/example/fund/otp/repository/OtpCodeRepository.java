package com.example.fund.otp.repository;


import com.example.fund.otp.entity.OtpCode;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface OtpCodeRepository extends JpaRepository<OtpCode, Long> {

    // 비관적 락 추가
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT o FROM OtpCode o WHERE o.email = :email " +
            "AND o.expiresAt > :now " +
            "AND o.isUsed = false " +
            "ORDER BY o.createdAt DESC " +
            "LIMIT 1")
    Optional<OtpCode> findValidOtpByEmailWithLock(
            @Param("email") String email,
            @Param("now") LocalDateTime now
    );

    // 기존 메서드들...
    @Query("SELECT o FROM OtpCode o WHERE o.email = :email " +
            "AND o.expiresAt > :now " +
            "AND o.isUsed = false " +
            "ORDER BY o.createdAt DESC " +
            "LIMIT 1")
    Optional<OtpCode> findValidOtpByEmail(
            @Param("email") String email,
            @Param("now") LocalDateTime now
    );

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query(value = "UPDATE /*+ BYPASS_UJVC */ OTP_CODES " +
            "SET IS_USED = 1 " +
            "WHERE EMAIL = :email AND IS_USED = 0",
            nativeQuery = true)
    int invalidateExistingOtps(@Param("email") String email);
}