package com.example.fund.admin.entity;


import jakarta.persistence.*;
import lombok.*;

@Entity
// 해당 클래스가 JPA Entity임을 나타내며,
// DB 테이블과 매핑되는 객체임을 의미
@Table(name="tbl_admin")
// 이 Entity가 매핑될 실제 DB 테이블 이름 지정

@AllArgsConstructor
// 모든 필드를 매개변수로 가지는 생성자 자동 생성

@NoArgsConstructor
// 기본 생성자 자동 생성 (JPA 필수)

@Getter
@Setter
// 모든 필드에 대한 Getter / Setter 자동 생성

@ToString
// 객체 출력 시 필드 값을 문자열로 반환
public class Admin {

    @Id
    // 해당 필드가 Primary Key(기본키)임을 나타냄

    @GeneratedValue(strategy = GenerationType.IDENTITY)
    // DB의 AUTO_INCREMENT(또는 IDENTITY) 전략을 사용하여
    // 기본키 값을 데이터베이스가 자동 생성
    private Integer admin_id;

    @Column(length = 20)
    // 관리자 로그인 아이디
    // 컬럼 길이를 20으로 제한
    private String adminname;

    @Column(length = 20)
    // 관리자 비밀번호
    // 실제 서비스에서는 암호화된 값 저장 권장
    private String password;

    // 관리자 실명
    private String name;

    @Column(length = 20)
    // 관리자 권한(Role) 정보
    // 예: ROLE_ADMIN, ROLE_SUPER 등
    private String role;

}