class AuthService {
  static const String adminEmail = 'admin@example.com';
  static const String adminPassword = 'admin123';

  bool signIn(String email, String password) {
    return email.trim() == adminEmail && password.trim() == adminPassword;
  }

  Future<void> signOut() async {
    // Здесь может быть логика выхода, если потребуется
    return Future.value();
  }
}
