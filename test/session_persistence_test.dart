import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dev_motors/core/services/api_service.dart';
import 'package:dev_motors/features/auth/presentation/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session Persistence & Auto-Login Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('1. saveAuthSession saves credentials and sets AuthProvider & ApiService state', () async {
      const token = 'test-token-12345';
      final user = {
        'id': 'user-1',
        'employeeId': 'nexa_muneesh_bsm',
        'name': 'Muneesh Kumar',
        'role': 'EMPLOYEE',
      };

      await ApiService.saveAuthSession(token, user);

      expect(ApiService.token, equals(token));
      expect(ApiService.currentUser, isNotNull);
      expect(ApiService.currentUser!['role'], equals('EMPLOYEE'));
      expect(AuthProvider().token, equals(token));
      expect(AuthProvider().role, equals('EMPLOYEE'));
      expect(AuthProvider().isAuthenticated, isTrue);
    });

    test('2. restoreSession restores user session from SharedPreferences on app startup', () async {
      // Simulate app killed and reopened with saved session in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'auth_token': 'persisted-jwt-token',
        'auth_user': '{"id":"usr-owner","employeeId":"main_om_owner","name":"Om Srivastava","role":"OWNER"}',
      });

      // Reset memory state to simulate fresh launch
      ApiService.setAuthSession('', {});
      AuthProvider().logout();

      final restored = await ApiService.restoreSession();

      expect(restored, isTrue);
      expect(ApiService.token, equals('persisted-jwt-token'));
      expect(ApiService.currentUser!['role'], equals('OWNER'));
      expect(AuthProvider().token, equals('persisted-jwt-token'));
      expect(AuthProvider().role, equals('OWNER'));
      expect(AuthProvider().isAuthenticated, isTrue);
    });

    test('3. restoreSession returns false when no session exists', () async {
      SharedPreferences.setMockInitialValues({});
      ApiService.setAuthSession('', {});
      AuthProvider().logout();

      final restored = await ApiService.restoreSession();

      expect(restored, isFalse);
      expect(ApiService.currentUser, isNull);
      expect(AuthProvider().isAuthenticated, isFalse);
    });

    test('4. logout removes session from SharedPreferences and resets state', () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'active-token',
        'auth_user': '{"id":"1","employeeId":"emp1","role":"EMPLOYEE"}',
      });

      await ApiService.restoreSession();
      expect(ApiService.token, equals('active-token'));

      await ApiService.logout();

      expect(ApiService.token, isNull);
      expect(ApiService.currentUser, isNull);
      expect(AuthProvider().token, isNull);
      expect(AuthProvider().isAuthenticated, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_user'), isNull);

      // Verify that next app launch won't auto-login
      final nextLaunchRestored = await ApiService.restoreSession();
      expect(nextLaunchRestored, isFalse);
    });
  });
}
