package com.example.ap.service.admin;

import java.util.List;

import com.example.common.dto.admin.AdminNoticeDTO;

public interface AdminNoticeService {
    List<AdminNoticeDTO> findRecentAdminNotices(int limit);
    void createAdminNotice(String title, String content, String author);

    AdminNoticeDTO findById(Long id);
    void updateAdminNotice(Long id, String title, String content);
    void deleteAdminNotice(Long id);
}
