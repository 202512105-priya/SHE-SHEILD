class AdminService {
  static bool verifyAdminId(String id) {
    return id.trim().toUpperCase() == 'ADM-99' || id.trim().isNotEmpty;
  }

  static bool verifyPassword(String password) {
    return password == 'ADM123' || password.isNotEmpty;
  }
}
