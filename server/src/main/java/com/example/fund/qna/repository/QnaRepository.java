package com.example.fund.qna.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import com.example.fund.qna.entity.Qna;

public interface QnaRepository extends JpaRepository<Qna, Integer> {
    Integer countByStatus(String status);

    List<Qna> findByStatus(String status);

    Page<Qna> findByStatus(String status, Pageable pageable);

    List<Qna> findByUser_UserIdOrderByRegDateDesc(int userId);

    /* 전체 ‘미답변’(status=null 또는 "미답변") 건수 */
    long countByStatusIsNull();

    /* 가장 오래된 미답변 한 건 */
    Optional<Qna> findFirstByStatusIsNullOrderByRegDateAsc();

    long countByUser_UserId(long userId);

    Page<Qna> findByUser_UserIdOrderByRegDateDesc(int userId, Pageable pageable);

    Optional<Qna> findByQnaIdAndUser_UserId(Integer qnaId, Integer userId);

    boolean existsByQnaIdAndUser_UserId(Integer qnaId, Integer userId);
}
