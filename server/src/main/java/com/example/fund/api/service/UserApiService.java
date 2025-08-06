package com.example.fund.api.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;

import com.example.fund.api.common.SignupRequest;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;

@Service
public class UserApiService {
    private final UserRepository userRepository;
    private final BCryptPasswordEncoder passwordEncoder;

    public UserApiService(UserRepository userRepository, BCryptPasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public boolean existsByUsername(String username) {
        return userRepository.existsByUsername(username);
    }

    public void save(SignupRequest req) {
        User user = User.builder()
                .username(req.getUsername()) // ← 필드명 맞춤
                .password(passwordEncoder.encode(req.getPassword()))
                .name(req.getName())
                .phone(req.getPhone())
                .email(req.getEmail())
                .build();
        userRepository.save(user);
    }

}
