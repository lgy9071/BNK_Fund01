package com.example.demo.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

import com.example.demo.security.JwtHandshakeInterceptor;
import com.example.demo.security.JwtTokenProvider;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Autowired
    JwtTokenProvider jwtTokenProvider;

    // 메시지 브로커 구성 (클라이언트가 구독할 주소)
    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // "/topic"으로 시작하는 메시지를 구독자에게 브로드캐스트
        config.enableSimpleBroker("/topic");

        // 클라이언트가 서버로 메시지를 보낼 때 prefix
        config.setApplicationDestinationPrefixes("/app");
    }

    

    // 클라이언트가 WebSocket으로 접속할 수 있는 endpoint 설정
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")  // 클라이언트가 접속할 WebSocket endpoint
                .addInterceptors(new JwtHandshakeInterceptor(jwtTokenProvider))
                .setAllowedOriginPatterns("*")  // 모든 origin 허용 (배포 시 도메인 제한 권장)
                .withSockJS();  // SockJS fallback 지원
    }

}
