enum UserRole { user, admin }

class UserRoleHelper {
  static const String _userRoleKey = 'user_role';

  static String roleToString(UserRole role) {
    return role.toString().split('.').last;
  }

  static UserRole stringToRole(String roleStr) {
    return UserRole.values.firstWhere(
      (role) => roleToString(role) == roleStr,
      orElse: () => UserRole.user,
    );
  }
}
