package com.example.fund.admin.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.admin.service.CustomerService;
import com.example.fund.admin.service.CustomerService.Detail;

import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/admin/api/customers")
@RequiredArgsConstructor
public class CustomerController {

    // 고객(회원) 관련 비즈니스 로직을 담당하는 Service
    private final CustomerService service;

    /*
     * 고객 검색 API
     * - GET /admin/api/customers/search
     *
     * 요청 파라미터:
     * - q : 검색어 (이름, 이메일, 아이디 등)
     *
     * 사용 목적:
     * - 관리자 페이지에서 고객 검색 자동완성 또는 목록 조회
     *
     * 반환값:
     * - 고객 목록(ListItem DTO 리스트)
     */
    @GetMapping("/search")
    public List<CustomerService.ListItem> search(
            @RequestParam("q") String q   // 검색 키워드
    ){
        return service.search(q);
    }

    /*
     * 고객 상세 정보 조회 API
     * - GET /admin/api/customers/{id}
     *
     * PathVariable:
     * - id : 고객(회원) 고유 ID
     *
     * 사용 목적:
     * - 관리자 페이지에서 특정 고객 상세 정보 조회
     *
     * 반환값:
     * - 고객 상세 정보 DTO
     */
    @GetMapping("/{id}")
    public Detail getDetail(
            @PathVariable("id") Long userId  // 조회할 고객 ID
    ) {
        return service.getDetail(userId);
    }
}
