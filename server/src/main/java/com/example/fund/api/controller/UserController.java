package com.example.fund.api.controller;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.api.common.SignupRequest;
import com.example.fund.api.service.UserApiService;

@RestController
@RequestMapping("/api")
public class UserController {

    @Autowired
    private UserApiService userApiService;

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody SignupRequest request) {
        if (userApiService.existsByUsername(request.getUsername())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("이미 사용중인 아이디입니다");
        }
        userApiService.save(request);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/check-id/{username}")
    public Map<String, Boolean> checkDuplicate(@PathVariable String username) {
        boolean duplicate = userApiService.existsByUsername(username);
        return Map.of("duplicate", duplicate);
    }
}
