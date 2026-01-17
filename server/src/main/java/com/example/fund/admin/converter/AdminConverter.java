package com.example.fund.admin.converter;

import com.example.fund.admin.dto.AdminDTO;
import com.example.fund.admin.entity.Admin;
import org.springframework.stereotype.Component;

@Component
public class AdminConverter {
    // DTO(Data Transfer Object)와 Entity 간의 변환을 담당하는 클래스
    // Controller ↔ Service ↔ Repository 계층 간 데이터 이동 시 사용됨

    /**
     * AdminDTO → Admin Entity 변환 메서드
     * 주로 클라이언트에서 전달받은 DTO 데이터를
     * DB에 저장하기 위해 Entity 객체로 변환할 때 사용
     *
     * @param adminDTO 변환 대상 AdminDTO 객체
     * @return 변환된 Admin Entity 객체
     */
    public Admin toAdminEntity(AdminDTO adminDTO) {
        // Admin Entity 객체 생성
        Admin admin = new Admin();

        // DTO의 관리자 ID를 Entity에 설정
        admin.setAdmin_id(adminDTO.getAdmin_id());

        // DTO의 권한(Role) 정보를 Entity에 설정
        admin.setRole(adminDTO.getRole());

        // DTO의 관리자 이름을 Entity에 설정
        admin.setName(adminDTO.getName());

        // DTO의 비밀번호를 Entity에 설정
        admin.setPassword(adminDTO.getPassword());

        // DTO의 관리자 로그인 아이디(adminname)를 Entity에 설정
        admin.setAdminname(adminDTO.getAdminname());

        // 변환이 완료된 Admin Entity 반환
        return admin;
    }

    /**
     * Admin Entity → AdminDTO 변환 메서드
     * DB에서 조회한 Entity 객체를
     * 클라이언트에 전달하기 위한 DTO로 변환할 때 사용
     *
     * @param admin 변환 대상 Admin Entity 객체
     * @return 변환된 AdminDTO 객체
     */
    public AdminDTO toAdminDTO(Admin admin) {
        // AdminDTO 객체 생성
        AdminDTO adminDTO = new AdminDTO();

        // Entity의 관리자 ID를 DTO에 설정
        adminDTO.setAdmin_id(admin.getAdmin_id());

        // Entity의 관리자 로그인 아이디(adminname)를 DTO에 설정
        adminDTO.setAdminname(admin.getAdminname());

        // Entity의 관리자 이름을 DTO에 설정
        adminDTO.setName(admin.getName());

        // Entity의 비밀번호를 DTO에 설정
        adminDTO.setPassword(admin.getPassword());

        // Entity의 권한(Role) 정보를 DTO에 설정
        adminDTO.setRole(admin.getRole());

        // 변환이 완료된 AdminDTO 반환
        return adminDTO;
    }
}
