enum UserRole { student, staff, hod, security }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.staff:
        return 'Staff Advisor';
      case UserRole.hod:
        return 'HOD';
      case UserRole.security:
        return 'Security';
    }
  }
}
