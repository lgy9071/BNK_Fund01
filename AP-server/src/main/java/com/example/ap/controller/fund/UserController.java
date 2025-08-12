package com.example.ap.controller.fund;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.common.entity.admin.SignupRequest;

//@CrossOrigin(origins = "http://10.71.200.224:8090")
@CrossOrigin(origins = "*")
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

    @GetMapping("/check-id")
    public Map<String, Boolean> checkDuplicate(@RequestParam(name = "username") String username) {
        System.out.println("중복검사");
        boolean duplicate = userApiService.existsByUsername(username);
        return Map.of("duplicate", duplicate);
    }
}
