package com.example.fund.api.controller;

import java.util.Map;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.example.fund.api.common.SignupRequest;
import com.example.fund.api.service.UserApiService;
import com.example.fund.common.CurrentUid;
import com.example.fund.user.entity.User;
import com.example.fund.user.repository.UserRepository;

//@CrossOrigin(origins = "http://10.71.200.224:8090")
@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api")
public class UserController {

    @Autowired
    private UserApiService userApiService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/signup")
    public ResponseEntity<?> signup(@RequestBody SignupRequest request) {
        if (userApiService.existsByUsername(request.getUsername())) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body("이미 사용중인 아이디입니다");
        }
        userApiService.save(request);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/check-id")
    public Map<String, Boolean> checkDuplicate(@RequestParam(name = "username") String username) {
        System.out.println("중복검사");
        boolean duplicate = userApiService.existsByUsername(username);
        return Map.of("duplicate", duplicate);
    }
}
