// com.example.fund.qna.controller.QnaApiController
package com.example.fund.qna.controller;

import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.example.fund.common.CurrentUid;
import com.example.fund.qna.dto.QnaCreateRequest;
import com.example.fund.qna.dto.QnaDto;
import com.example.fund.qna.dto.QnaUpdateRequest;
import com.example.fund.qna.service.QnaApiService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

// @CurrentUid는 프로젝트에 이미 있는 커스텀 리졸버 사용
@RestController
@RequiredArgsConstructor
@RequestMapping("/api/qna")
public class QnaApiController {

    private final QnaApiService qnaApiService;

    @GetMapping
    public ResponseEntity<Page<QnaDto>> myQnas(
            @CurrentUid Integer uid,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size
    ) {
        return ResponseEntity.ok(qnaApiService.myQnas(uid, page, size));
    }

    @GetMapping("/{qnaId}")
    public ResponseEntity<QnaDto> getMyQna(@CurrentUid Integer uid, @PathVariable int qnaId) {
        return ResponseEntity.ok(qnaApiService.getMyQna(uid, qnaId));
    }

    @PostMapping
    public ResponseEntity<QnaDto> create(@CurrentUid Integer uid, @RequestBody @Valid QnaCreateRequest req) {
        return ResponseEntity.ok(qnaApiService.create(uid, req));
    }

    @PutMapping("/{qnaId}")
    public ResponseEntity<QnaDto> updatePending(
            @CurrentUid Integer uid,
            @PathVariable int qnaId,
            @RequestBody @Valid QnaUpdateRequest req
    ) {
        return ResponseEntity.ok(qnaApiService.updatePending(uid, qnaId, req));
    }
}
