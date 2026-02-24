import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:developer';

class NotificationService {
  static String get appId => dotenv.get('ONESIGNAL_APP_ID');
  static String get restApiKey => dotenv.get('ONESIGNAL_REST_API_KEY');

  static Future<void> initialize() async {
    // Debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialization
    OneSignal.initialize(appId);

    // Request permissions
    OneSignal.Notifications.requestPermission(true);
  }

  static Future<void> login(String uid) async {
    try {
      await OneSignal.login(uid);
      log("OneSignal logged in with UID: $uid");
    } catch (e) {
      log("Error logging in to OneSignal: $e");
    }
  }

  static Future<void> logout() async {
    try {
      await OneSignal.logout();
    } catch (e) {
      log("Error logging out of OneSignal: $e");
    }
  }

  // Send a notification to specific user IDs (External User IDs)
  static Future<void> sendNotification({
    required List<String> playerIds, // These correspond to external UIDs
    required String title,
    required String body,
  }) async {
    if (playerIds.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode({
          'app_id': appId,
          'include_external_user_ids': playerIds,
          'headings': {'en': title},
          'contents': {'en': body},
        }),
      );

      if (response.statusCode == 200) {
        log("OneSignal notification sent successfully");
      } else {
        log("Error sending OneSignal notification: ${response.body}");
      }
    } catch (e) {
      log("Exception sending OneSignal notification: $e");
    }
  }
}
