package com.example.ap.service.admin;


import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.kafka.KafkaProperties.Admin;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import com.example.ap.converter.admin.AdminConverter;
import com.example.ap.repository.admin.AdminRepository_A;
import com.example.common.dto.admin.AdminDTO;

@Service
public class AdminService_A {

    @Autowired
    AdminRepository_A adminRepository_a;

    @Autowired
    AdminConverter adminConverter;

    //ID, Password 일치 여부에 따라 boolean 값 리턴
    public boolean login(AdminDTO adminDTO){
        Optional<Admin> admin = adminRepository_a.findByAdminnameAndPassword(adminDTO.getAdminname(), adminDTO.getPassword());
        return admin.isPresent();
    }

    //로그인 된 admin 조회
    public Admin searchAdmin(AdminDTO adminDTO){
        Optional<Admin> optionalAdmin = adminRepository_a.findByAdminnameAndPassword(adminDTO.getAdminname(), adminDTO.getPassword());
        Admin admin = null;
        if(optionalAdmin.isPresent()){
            admin = optionalAdmin.get();
        }

        return admin;
    }

    //ID 중복 검사
    public boolean check_id(String adminname){
        return adminRepository_a.existsByAdminname(adminname);
    }

    //관리자 등록
    public void adminRegist(AdminDTO adminDTO){
        adminDTO.setPassword("1234");//초기 등록시 비밀번호 1234로 고정
        Admin admin = adminConverter.toAdminEntity(adminDTO);

        adminRepository_a.save(admin);
    }

    //전체 관리자 목록 (Entity => DTO로 변환해서 출력)
    // public List<AdminDTO> getAllAdmins(){
    //     List<Admin> admins = adminRepository_a.findAll();
    //     List<AdminDTO> adminDTOS = new ArrayList<>();
    //     for(Admin admin : admins){
    //         AdminDTO convertAdmin = adminConverter.toAdminDTO(admin);
    //         adminDTOS.add(convertAdmin);
    //     }
    //     return adminDTOS;
    // }

    //Role별로 관리자 조회하여 출력(Entity => DTO로 변환해서 출력)
    // public List<AdminDTO> getAdminsByRole(String role){
    //     List<Admin> admins = adminRepository_a.findByRole(role);
    //     List<AdminDTO> adminDTOS = new ArrayList<>();
    //     for(Admin admin : admins){
    //         AdminDTO convertAdmin = adminConverter.toAdminDTO(admin);
    //         adminDTOS.add(convertAdmin);
    //     }
    //     return adminDTOS;
    // }


    //전체 관리자 목록 (Entity => DTO로 변환해서 출력) + 페이지네이션
    public Page<AdminDTO> getAllAdmins(Pageable pageable) {
        return adminRepository_a.findAll(pageable) 
            .map(adminConverter::toAdminDTO);
    }

    //Role별로 관리자 조회하여 출력(Entity => DTO로 변환해서 출력) + 페이지네이션
    public Page<AdminDTO> getAdminsByRole(String role, Pageable pageable) {
        return adminRepository_a.findByRole(role, pageable)
            .map(adminConverter::toAdminDTO);
    }


    //관리자 ID로 정보 찾기
    public AdminDTO findById(Integer id){
        Admin admin = new Admin();
        AdminDTO adminDTO = new AdminDTO();
        Optional<Admin> optionalAdmin = adminRepository_a.findById(id);
        admin = optionalAdmin.get();
        adminDTO = adminConverter.toAdminDTO(admin);

        return adminDTO;
    }

    //관리자 ROLE 수정
    public void updateRole(Integer id, String role){
        Admin admin = adminRepository_a.findById(id).orElseThrow();
        admin.setRole(role);
        adminRepository_a.save(admin);
    }

    //관리자 삭제
    public void deleteAdmin(Integer id){
        adminRepository_a.deleteById(id);
    }
}

