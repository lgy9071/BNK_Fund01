# 📌 BNK Financial Platform – 펀드 관리 & 판매 통합 서비스

> “관리자와 사용자 양쪽 금융 프로세스를 모두 구현한 실무형 펀드 플랫폼”

BNK Financial Platform은 **펀드 관리자 시스템(Admin)** 과  
**사용자 펀드 판매 서비스(User)** 를 하나의 금융 플랫폼으로 통합한 프로젝트입니다.

Spring Boot 기반의 백엔드와 Flutter 기반 사용자 앱(WebView 포함)의 구조로  
실제 은행의 펀드 판매 절차—**계좌 → 투자성향 → 가입 → 보유 → 환매 → 리뷰**—를 구현했습니다.

---

## 🧠 Tech Stack

| 영역 | 기술 |
|------|------|
| Backend | Java 21, Spring Boot 3.5, Spring Security(JWT), JPA, Lombok |
| Frontend(App/Web) | HTML5, CSS3, JavaScript, Flutter(WebView) |
| Database | MariaDB |
| AI 기능 | OpenAI API (비교·추천·리뷰 분석) |
| Batch | Spring Batch, Scheduler |
| Build | Gradle |
| Tools | IntelliJ, Android Studio, GitHub, Notion |

---

## 🚀 대표 기능

### 👨‍💼 관리자(Admin)
- 펀드 상품 CRUD
- 공시문서 업로드 및 다운로드 관리
- FAQ / 1:1 문의 / 공시문서 관리
- 결재(기안 → 승인/반려 → 배포) 프로세스 구축
- Role 기반 접근 제어 (super / planner / approver / cs)
- 관리자 전용 대시보드(통계 카드 + 차트 UI)

---

### 👤 사용자(User)
- 계좌 개설 → 투자성향분석 → 펀드 가입 전체 흐름 구현
- 펀드 목록, 상세, 공시문서 다운로드
- 보유 펀드 조회 및 평가금액 계산
- 입출금 내역 조회 + Excel 다운로드 기능
- 리뷰 작성 및 AI 감성 분석 요약 제공
- 투자 성향 및 과거 투자 이력 기반 펀드 추천 기능

---

## 🧩 담당 기능 요약 (이지용)
- 결재(Approval) 전체 흐름 구현  
- 관리자 메인페이지 + Role 기반 기능 분리  
- 공시문서 다운로드 시스템 구축
- FAQ 관리 시스템(등록/수정/삭제)
- Flutter ↔ Spring JWT 인증 연동  
- 사용자 보유현황/입출금 조회 UI 구현  
- Excel Export 및 금융 계산 UI 개발  

---

## 📽 시연 영상
https://www.youtube.com/watch?v=qDJmfQTorm8

---

## 📎 Repository
- https://github.com/jiyonglee/BNK_project01  
- https://github.com/jiyonglee/BNK_project02

---
