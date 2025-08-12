package com.example.ap.converter.admin;


import org.springframework.stereotype.Component;

@Component
public class AdminConverter {
    // DTO -> Entity, Entity -> DTO 변환 클래스

    public Admin toAdminEntity(AdminDTO adminDTO) {
        Admin admin = new Admin();
        admin.setAdmin_id(adminDTO.getAdmin_id());
        admin.setRole(adminDTO.getRole());
        admin.setName(adminDTO.getName());
        admin.setPassword(adminDTO.getPassword());
        admin.setAdminname(adminDTO.getAdminname());
        return admin;   
    }

    public AdminDTO toAdminDTO(Admin admin) {
        AdminDTO adminDTO = new AdminDTO();
        adminDTO.setAdmin_id(admin.getAdmin_id());
        adminDTO.setAdminname(admin.getAdminname());
        adminDTO.setName(admin.getName());
        adminDTO.setPassword(admin.getPassword());
        adminDTO.setRole(admin.getRole());
        return adminDTO;
    }
}
