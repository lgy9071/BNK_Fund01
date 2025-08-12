package com.example.ap.repository.fund;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.example.common.entity.fund.User;

public interface UserRepository extends JpaRepository<User, Integer> {
    Optional<User> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByPhone(String phone);

    boolean existsByPhoneAndUserIdNot(String phone, int userId);

    Optional<User> findByUserId(Integer userId);
}
