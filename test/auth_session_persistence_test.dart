import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_motors/core/services/api_service.dart';
import 'package:dev_motors/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await ApiService.logout();
  });

  group('9-Hour Session Persistence & Auto-Login Tests', () {
    test('1. saveAuthSession stores token, user, and timestamp within SharedPreferences and updates AuthProvider', () async {
      final user = {
        'employeeId': 'TEST_MGR',
        'name': 'Branch Manager',
        'role': 'MANAGER',
        'branch': 'Aligarh Nexa',
      };
      const token = 'jwt-token-xyz-123';

      await ApiService.saveAuthSession(token, user);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ApiService.prefAuthToken), equals(token));
      expect(prefs.getInt(ApiService.prefAuthTimestamp), isNotNull);
      expect(jsonDecode(prefs.getString(ApiService.prefAuthUser)!), equals(user));

      // In-memory state check
      expect(ApiService.token, equals(token));
      expect(ApiService.currentUser?['employeeId'], equals('TEST_MGR'));
      expect(AuthProvider().token, equals(token));
      expect(AuthProvider().role, equals('MANAGER'));
    });

    test('2. restoreSession succeeds when session is valid and less than 9 hours old', () async {
      final prefs = await SharedPreferences.getInstance();
      final user = {
        'employeeId': 'nexa_muneesh_bsm',
        'name': 'Muneesh Kumar',
        'role': 'EMPLOYEE',
      };
      const token = 'active-jwt-token';
      // Login happened 2 hours ago (within 9 hour window)
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch;

      await prefs.setString(ApiService.prefAuthToken, token);
      await prefs.setString(ApiService.prefAuthUser, jsonEncode(user));
      await prefs.setInt(ApiService.prefAuthTimestamp, twoHoursAgo);

      // Reset in-memory static variables to simulate clean app restart
      ApiService.setAuthSession('', {});
      AuthProvider().logout();

      final restored = await ApiService.restoreSession();

      expect(restored, isTrue);
      expect(ApiService.token, equals(token));
      expect(ApiService.currentUser?['employeeId'], equals('nexa_muneesh_bsm'));
      expect(AuthProvider().role, equals('EMPLOYEE'));
      expect(AuthProvider().isAuthenticated, isTrue);
    });

    test('3. restoreSession fails and wipes session when session is older than 9 hours', () async {
      final prefs = await SharedPreferences.getInstance();
      final user = {
        'employeeId': 'TEST01',
        'name': 'Tester 01',
        'role': 'EMPLOYEE',
      };
      const token = 'expired-jwt-token';
      // Login happened 9 hours and 5 minutes ago (expired!)
      final expiredTime = DateTime.now().subtract(const Duration(hours: 9, minutes: 5)).millisecondsSinceEpoch;

      await prefs.setString(ApiService.prefAuthToken, token);
      await prefs.setString(ApiService.prefAuthUser, jsonEncode(user));
      await prefs.setInt(ApiService.prefAuthTimestamp, expiredTime);

      final restored = await ApiService.restoreSession();

      expect(restored, isFalse);
      expect(ApiService.token, isNull);
      expect(ApiService.currentUser, isNull);
      expect(AuthProvider().isAuthenticated, isFalse);

      // Verify that SharedPreferences keys were cleared
      expect(prefs.getString(ApiService.prefAuthToken), isNull);
      expect(prefs.getString(ApiService.prefAuthUser), isNull);
      expect(prefs.getInt(ApiService.prefAuthTimestamp), isNull);
    });

    test('4. ApiService.logout cleanly wipes both storage and memory', () async {
      final user = {'employeeId': 'owner_dron', 'role': 'OWNER'};
      await ApiService.saveAuthSession('owner-token', user);

      expect(ApiService.token, equals('owner-token'));

      await ApiService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ApiService.prefAuthToken), isNull);
      expect(prefs.getString(ApiService.prefAuthUser), isNull);
      expect(prefs.getInt(ApiService.prefAuthTimestamp), isNull);
      expect(ApiService.token, isNull);
      expect(ApiService.currentUser, isNull);
      expect(AuthProvider().isAuthenticated, isFalse);
    });
  });
}
