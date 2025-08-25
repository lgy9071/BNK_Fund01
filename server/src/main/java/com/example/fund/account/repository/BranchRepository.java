package com.example.fund.account.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.example.fund.account.entity.Branch;

public interface BranchRepository extends JpaRepository<Branch, Long> {

 List<Branch> findAllByLatIsNullOrLngIsNull();
 
 Optional<Branch> findByBranchName(String branchName);

 Optional<Branch> findByBranchId(Long id);

 // (선택) 주어진 범위 박스 내 검색(간단 반경검색 대용)
 @Query("""
   select b from Branch b
   where b.lat between :minLat and :maxLat
     and b.lng between :minLng and :maxLng
 """)
 List<Branch> findInBoundingBox(@Param("minLat") double minLat,
                                @Param("maxLat") double maxLat,
                                @Param("minLng") double minLng,
                                @Param("maxLng") double maxLng);

 // (선택) 공간 인덱스 사용한 원형 반경 검색(POINT 있을 때) — MySQL 함수 직접 사용
 @Query(value = """
   SELECT * FROM branch
   WHERE coord IS NOT NULL
     AND ST_Distance_Sphere(coord, ST_SRID(POINT(:lng, :lat), 4326)) <= :radiusMeters
   """, nativeQuery = true)
 List<Branch> findWithinRadius(@Param("lat") double lat,
                               @Param("lng") double lng,
                               @Param("radiusMeters") double radiusMeters);
 
//근처 후보(바운딩박스) 조회용 — 좌표가 채워진 뒤 사용
 List<Branch> findByLatBetweenAndLngBetween(Double minLat, Double maxLat,
                                            Double minLng, Double maxLng);
 
 Page<Branch> findByLatIsNullOrLngIsNull(Pageable pageable);
 
 Page<Branch> findByLatIsNullOrLngIsNullOrLatEqualsAndLngEquals(
         Double lat, Double lng, Pageable pageable
 );
 
 
}
