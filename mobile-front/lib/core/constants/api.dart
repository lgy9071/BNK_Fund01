class ApiConfig {
  // 기본 서버 주소 (IP/포트 변경 시 여기만 수정)
  static const String baseUrl = 'http://192.168.100.245:8090';

  // 회원가입 API
  static const String signup = '$baseUrl/api/signup';

  // 로그인 API
  static const String login = '$baseUrl/api/auth/login';

  // 아이디 중복확인 API
  static const String checkUsername = '$baseUrl/api/check-id';
}
