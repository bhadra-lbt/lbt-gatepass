import 'package:firebase_auth/firebase_auth.dart';

class AuthErrorHandler {
  static String getMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email. Please register first.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password accounts are not enabled.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'email-already-in-use':
          return 'This email is already registered. Try logging in.';
        case 'weak-password':
          return 'Password is too weak. Use a stronger password.';
        case 'invalid-credential':
          return 'Invalid login credentials. Please check your email and password.';
        case 'channel-error':
          return 'Please enter both email and password.';
        default:
          return 'An authentication error occurred (Code: ${error.code})';
      }
    }

    // Fallback for other errors
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('network')) {
      return 'Connection failed. Check your internet.';
    }

    return 'Something went wrong. Please try again.';
  }
}
