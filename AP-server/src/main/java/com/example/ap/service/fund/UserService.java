package com.example.ap.service.fund;


import org.springframework.security.crypto.bcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.ap.repository.fund.QnaRepository;
import com.example.ap.repository.fund.UserRepository;
import com.example.ap.service.admin.CompareAiService;
import com.example.common.dto.fund.JoinRequest;
import com.example.common.dto.fund.UserUpdateRequest;
import com.example.common.entity.fund.User;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class UserService {

    private final InvestProfileResultRepository investProfileResultRepository;
    private final UserRepository repo;
    private final CompareAiService compareAiService;
    private final QnaRepository qnaRepository;

    /* ---------- 회원가입 ---------- */
    @Transactional
    public void register(JoinRequest dto) {
        if (repo.existsByUsername(dto.getUsername())) {
            throw new IllegalStateException("이미 사용 중인 아이디입니다.");
        }
        if (repo.existsByPhone(dto.getPhone())) {
            throw new IllegalStateException("이미 등록된 전화번호입니다.");
        }

        // 전화번호 포맷 정리
        String rawPhone = dto.getPhone().replaceAll("[^0-9]", "");
        String formattedPhone = rawPhone.replaceAll("(\\d{3})(\\d{3,4})(\\d{4})", "$1-$2-$3");

        // 비밀번호 해싱
        String hashedPw = BCrypt.hashpw(dto.getPassword(), BCrypt.gensalt());

        User user = User.builder()
                .username(dto.getUsername())
                .password(hashedPw)
                .name(dto.getName())
                .phone(formattedPhone)
                .build();

        repo.save(user);
    }

    /* ---------- 로그인 ---------- */
    public User login(String id, String pw) {
        return repo.findByUsername(id)
                .filter(u -> BCrypt.checkpw(pw, u.getPassword()))
                .orElse(null);
    }

    /* ---------- 회원 정보 수정 ---------- */
    @Transactional
    public User updateProfile(int userId, @Valid UserUpdateRequest dto) {
        User user = repo.findById(userId)
                .orElseThrow(() -> new IllegalStateException("회원이 존재하지 않습니다."));

        // 현재 비밀번호 검증
        if (!BCrypt.checkpw(dto.getCurrentPassword(), user.getPassword())) {
            throw new IllegalStateException("현재 비밀번호가 일치하지 않습니다.");
        }

        // 새 비밀번호 변경 처리
        if (dto.isChangingPassword()) {
            if (!dto.newPwMatches()) {
                throw new IllegalStateException("새 비밀번호가 서로 다릅니다.");
            }
            String hashed = BCrypt.hashpw(dto.getNewPassword(), BCrypt.gensalt());
            user.setPassword(hashed);
        }

        // 전화번호 중복 확인 (본인 제외)
        if (!user.getPhone().equals(dto.getPhone())
                && repo.existsByPhoneAndUserIdNot(dto.getPhone(), userId)) {
            throw new IllegalStateException("이미 사용 중인 전화번호입니다.");
        }

        // 이름/전화번호 업데이트
        user.setName(dto.getName());
        user.setPhone(dto.getPhone());

        return user; // 컨트롤러에서 세션 갱신용으로 반환
    }

    public String user_invertType(Integer userId) {
        InvestProfileResult invest = investProfileResultRepository
                .findByUser_UserId(userId)
                .orElse(null);

        String result = "";
        if (invest == null) {
            result = "투자성향 분석결과가 없어요";
        } else {
            result = invertConvert(invest.getType().getTypeId());
        }

        return result;
    }

    // 받아온 투자성향결과 Inteager -> String 변환 함수
    private String invertConvert(Long invert) {
        String result = "";
        switch (invert.intValue()) {
            case 1:
                result = "안정형";
                break;

            case 2:
                result = "안정 추구형";
                break;

            case 3:
                result = "위험 중립형";
                break;
            case 4:
                result = "적극 투자형";
                break;
            case 5:
                result = "공격 투자형";
                break;

            default:
                break;
        }

        return result;
    }

    public long countUserQna(long id) {
        long result = qnaRepository.countByUser_UserId(id);
        return result;
    }
}

