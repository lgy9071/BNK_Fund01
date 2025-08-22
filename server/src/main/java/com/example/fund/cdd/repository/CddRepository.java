package com.example.fund.cdd.repository;

import com.example.fund.cdd.entity.CddEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CddRepository extends JpaRepository<CddEntity, Long> {
    List<CddEntity> findByUserIdOrderByCreatedAtDesc(Long userId);
    Optional<CddEntity> findByUserIdAndRrn(Long userId, String encryptedRrn);
}