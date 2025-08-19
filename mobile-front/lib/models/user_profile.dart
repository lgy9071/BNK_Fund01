class UserProfile {
  final int userId;
  final String username;
  final String name;
  final String email;

  UserProfile({
    required this.userId,
    required this.username,
    required this.name,
    required this.email,
  });

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    userId: _asInt(j['userId'] ?? j['id']),
    username: (j['username'] ?? j['loginId'] ?? '').toString(),
    name: (j['name'] ?? j['nickname'] ?? j['fullName'] ?? '').toString(),
    email: (j['email'] ?? '').toString(),
  );
}