class ApiConfig {
  // 기본 서버 주소 (IP/포트 변경 시 여기만 수정)
  static const String baseUrl = 'http://10.0.2.2:8090';

  // 회원가입 API
  static const String signup = '$baseUrl/api/signup';

  // 로그인 API
  static const String login = '$baseUrl/api/auth/login';

  // 아이디 중복확인 API
  static const String checkUsername = '$baseUrl/api/check-id';

  //엑세스 토큰
  static const String extend = '$baseUrl/api/auth/extend';

  // refresh 토큰
  static const String refresh = '$baseUrl/api/auth/refresh';

  // logout
  static const String logout = '$baseUrl/api/auth/logout';

  //마이페이지 카드용 프로필
  static const String userMe = '$baseUrl/api/users/me';

  // 펀드 API
  static const String funds = '$baseUrl/api/funds';
  static String fundDetail(String fundId) => '$baseUrl/api/funds/$fundId';
}
