package com.example.fund.common.config;

import java.time.Duration;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.core.DelegatingOAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtTimestampValidator;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;

import com.example.fund.common.JwtUtil;

@Configuration
public class SecurityConfig {

        private final JwtUtil jwtUtil;

        @Value("${jwt.access-secret}")
        private String accessSecret;

        SecurityConfig(JwtUtil jwtUtil) {
                this.jwtUtil = jwtUtil;
        }

        @Bean
        public SecurityFilterChain filterChain(HttpSecurity http,
                        JwtDecoder jwtDecoder) throws Exception {
                System.out.println("[Security] using decoder = " + jwtDecoder.getClass().getName());
                http
                                .csrf(csrf -> csrf.disable())
                                .sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                                .authorizeHttpRequests(auth -> auth
                                                .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                                                .anyRequest().permitAll() // ← 전부 개방
                                )
                                .formLogin(form -> form.disable())
                                .httpBasic(basic -> basic.disable())
                                // .oauth2ResourceServer(oauth -> oauth.jwt(jwt -> jwt.decoder(jwtDecoder())));
                                .oauth2ResourceServer(oauth -> oauth
                                                .jwt(jwt -> jwt.decoder(jwtDecoder)));
                return http.build();
        }

        @Bean
        public JwtDecoder jwtDecoder() {
                // System.out.println("[Custom JwtDecoder Bean] created with key hash = "
                // + jwtUtil.getAccessKey().hashCode()); //디버깅 코드
                NimbusJwtDecoder decoder = NimbusJwtDecoder.withSecretKey(jwtUtil.getAccessKey())
                                .macAlgorithm(MacAlgorithm.HS384)
                                .build();

                // exp/nbf 기본 검증 + (선택) 60초 시계오차 허용 + token_type=access 검증
                OAuth2TokenValidator<Jwt> tokenTypeValidator = jwt -> {
                        String t = jwt.getClaimAsString("token_type");
                        return "access".equals(t)
                                        ? OAuth2TokenValidatorResult.success()
                                        : OAuth2TokenValidatorResult.failure(new OAuth2Error("invalid_token",
                                                        "token_type!=access", ""));
                };

                decoder.setJwtValidator(new DelegatingOAuth2TokenValidator<>(
                                JwtValidators.createDefault(),
                                new JwtTimestampValidator(Duration.ofSeconds(60)),
                                tokenTypeValidator));
                return decoder;
        }

}
