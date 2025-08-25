// com.example.fund.qna.service.QnaApiService
package com.example.fund.qna.service;

import com.example.fund.qna.dto.QnaCreateRequest;
import com.example.fund.qna.dto.QnaDto;
import com.example.fund.qna.dto.QnaUpdateRequest;
import com.example.fund.qna.entity.Qna;
import com.example.fund.qna.repository.QnaRepository;
import com.example.fund.user.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class QnaApiService {

    private final QnaRepository qnaRepository;

    public Page<QnaDto> myQnas(int uid, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("regDate").descending());
        Page<Qna> p = qnaRepository.findByUser_UserIdOrderByRegDateDesc(uid, pageable);
        return p.map(q -> new QnaDto(
                q.getQnaId(), q.getTitle(), q.getContent(),
                q.getRegDate(), q.getStatus(), q.getAnswer()
        ));
    }

    public QnaDto getMyQna(int uid, int qnaId) {
        Qna q = qnaRepository.findByQnaIdAndUser_UserId(qnaId, uid)
                .orElseThrow(() -> new NoSuchElementException("문의가 존재하지 않습니다."));
        return new QnaDto(q.getQnaId(), q.getTitle(), q.getContent(),
                q.getRegDate(), q.getStatus(), q.getAnswer());
    }

    @Transactional
    public QnaDto create(int uid, QnaCreateRequest req) {
        Qna q = new Qna();
        q.setTitle(req.getTitle());
        q.setContent(req.getContent());
        q.setStatus("대기");
        User u = new User();
        u.setUserId(uid);
        q.setUser(u);
        Qna saved = qnaRepository.save(q);
        return new QnaDto(saved.getQnaId(), saved.getTitle(), saved.getContent(),
                saved.getRegDate(), saved.getStatus(), saved.getAnswer());
    }

    @Transactional
    public QnaDto updatePending(int uid, int qnaId, QnaUpdateRequest req) {
        Qna q = qnaRepository.findByQnaIdAndUser_UserId(qnaId, uid)
                .orElseThrow(() -> new NoSuchElementException("문의가 존재하지 않습니다."));
        if (!"대기".equals(q.getStatus())) {
            throw new IllegalStateException("대기 상태에서만 수정할 수 있습니다.");
        }
        q.setTitle(req.getTitle());
        q.setContent(req.getContent());
        Qna saved = qnaRepository.save(q);
        return new QnaDto(saved.getQnaId(), saved.getTitle(), saved.getContent(),
                saved.getRegDate(), saved.getStatus(), saved.getAnswer());
    }
}
