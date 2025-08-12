package com.example.ap.service.fund;

import java.util.List;
import java.util.NoSuchElementException;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import com.example.ap.repository.fund.QnaRepository;
import com.example.common.entity.fund.Qna;

@Service
public class QnaService {

    @Autowired
    private QnaRepository qnaRepository;

    public int countUnanwseQna() {
        return qnaRepository.countByStatus("대기");
    }

    public List<Qna> getQnaList(String status) {
        return qnaRepository.findByStatus(status);
    }

    public Qna getQna(Integer id) {
        Optional<Qna> optionalQna = qnaRepository.findById(id);
        Qna qna = optionalQna.get();

        return qna;
    }

    public void SubmitAnswer(Integer qnaId, String answer) {
        Qna qna = qnaRepository.findById(qnaId).orElseThrow();

        qna.setAnswer(answer);
        qna.setStatus("완료");

        qnaRepository.save(qna);
    }

    public List<Qna> getQnaListByUser(int userId) {
        return qnaRepository.findByUser_UserIdOrderByRegDateDesc(userId);
    }

    public Qna getQnaById(Long qnaId) {
        return qnaRepository.findById(Math.toIntExact(qnaId))
                .orElseThrow(() -> new NoSuchElementException("문의가 존재하지 않습니다."));
    }

    // 한페이지당 15개 게시글 보이도록 return
    public Page<Qna> getQnaListByStatus(String status, int page) {
        Pageable pageable = PageRequest.of(page, 10, Sort.by("regDate").descending()); // 최신순 정렬
        return qnaRepository.findByStatus(status, pageable);
    }

    /** 상위 `limit`개 미답변 문의를 최신순으로 가져옴 */
    public List<Qna> findRecentUnanswered(int limit) {
        Page<Qna> page = getQnaListByStatus("대기", 0);
        return page.getContent().stream()
                .limit(limit)
                .toList();
    }
}
