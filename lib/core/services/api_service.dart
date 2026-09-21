import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class ApiService {
  static const String baseUrl = 'https://dev-motors-backend.onrender.com/api';
  static String? _token;
  static Map<String, dynamic>? _currentUser;

  static String? get token => _token;
  static Map<String, dynamic>? get currentUser => _currentUser;

  static void setAuthSession(String tokenVal, Map<String, dynamic> userVal) {
    _token = tokenVal;
    _currentUser = userVal;
    AuthProvider().setSession(tokenVal, userVal);
  }

  static Future<void> saveAuthSession(String tokenVal, Map<String, dynamic> userVal) async {
    setAuthSession(tokenVal, userVal);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', tokenVal);
    await prefs.setString('auth_user', jsonEncode(userVal));
  }

  static Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      final userStr = prefs.getString('auth_user') ?? '';

      if (token.isEmpty || userStr.isEmpty) {
        _token = null;
        _currentUser = null;
        AuthProvider().logout();
        return false;
      }

      final decoded = jsonDecode(userStr);
      if (decoded is! Map) {
        _token = null;
        _currentUser = null;
        AuthProvider().logout();
        return false;
      }

      final userMap = Map<String, dynamic>.from(decoded);
      setAuthSession(token, userMap);
      return true;
    } catch (_) {
      _token = null;
      _currentUser = null;
      AuthProvider().logout();
      return false;
    }
  }

  static Future<String> getToken() async {
    if (_token != null && _token!.isNotEmpty) return _token!;
    final valid = await restoreSession();
    return valid ? (_token ?? '') : '';
  }

  static String cleanErrorMessage(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';
    final str = error.toString();
    final lower = str.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('onrender.com') ||
        lower.contains('clientexception') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('connection reset') ||
        lower.contains('handshakeexception')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return str.replaceAll('Exception:', '').replaceAll('Exception', '').trim();
  }

  // 1. LOGIN
  static Future<Map<String, dynamic>> login(String employeeId, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'password': password,
        }),
      );

      final decoded = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final token = decoded['data']?['token'] ?? decoded['token'] ?? '';
        final user = decoded['data']?['user'] ?? decoded['user'] ?? decoded['data'] ?? {};
        await saveAuthSession(token, Map<String, dynamic>.from(user));

        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // 2. FORGOT / RESET PASSWORD
  static Future<Map<String, dynamic>> forgotPassword(String employeeId, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'employeeId': employeeId,
          'newPassword': newPassword,
        }),
      );
      final decoded = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // 3. CHANGE PASSWORD
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final t = await getToken();
      final res = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final decoded = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return decoded;
      } else {
        throw Exception(decoded['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception(cleanErrorMessage(e));
    }
  }

  // 3b. UPDATE PROFILE (Phone, Avatar, Name)
  static Future<Map<String, dynamic>> updateProfile({
    String? phone,
    String? avatarUrl,
    String? name,
  }) async {
    final t = await getToken();
    final user = Map<String, dynamic>.from(_currentUser ?? {});
    final empId = user['employeeId'] ?? user['id'] ?? '';

    // Immediate optimistic update to local cache
    if (phone != null) {
      user['phone'] = phone;
      user['phoneNumber'] = phone;
      user['mobile'] = phone;
    }
    if (avatarUrl != null) {
      user['avatarUrl'] = avatarUrl;
      user['profileImage'] = avatarUrl;
    }
    if (name != null) user['name'] = name;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user));

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode({
          'employeeId': empId,
          if (phone != null) 'phone': phone,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
          if (name != null) 'name': name,
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is Map) {
          final serverUser = Map<String, dynamic>.from(decoded['data']);
          _currentUser = {...user, ...serverUser};
          await prefs.setString('auth_user', jsonEncode(_currentUser));
        }
        return decoded;
      }
    } catch (_) {}

    return {'success': true, 'data': user};
  }

  // 4. CATEGORIES
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/expenses/categories'));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List && (decoded['data'] as List).isNotEmpty) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
    } catch (_) {}
    return [
      {"id": "b87165b9-fc92-4444-8573-13240e421837", "name": "General Expenses"},
      {"id": "b87165b9-fc92-4444-8573-13240e421837", "name": "Fuel & Travel"},
      {"id": "b87165b9-fc92-4444-8573-13240e421837", "name": "Repair & Maintenance"},
      {"id": "b87165b9-fc92-4444-8573-13240e421837", "name": "Office Supplies"},
    ];
  }

  // 5. GET EXPENSES
  static Future<List<dynamic>> getExpenses() async {
    final t = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/expenses'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List) {
          return List<dynamic>.from(decoded['data']);
        }
      }
    } catch (_) {}
    return [];
  }

  // 6. CREATE EXPENSE
  static Future<Map<String, dynamic>> createExpense({
    String? category,
    String? categoryId,
    required double amount,
    required String description,
    String? vehicleNumber,
    String? location,
    String? receiptImage,
    String? receiptUrl,
    String? receiptFileName,
    String? receiptMimeType,
    dynamic receiptSize,
  }) async {
    final t = await getToken();
    final effectiveCatId = (categoryId != null && categoryId.isNotEmpty)
        ? categoryId
        : 'b87165b9-fc92-4444-8573-13240e421837';

    final effectiveLoc = location ??
        (_currentUser?['location'] is Map ? _currentUser!['location']['name'] : null) ??
        _currentUser?['branch'] ??
        _currentUser?['location'];

    final body = jsonEncode({
      'amount': amount,
      'description': description,
      'categoryId': effectiveCatId,
      'expenseDate': DateTime.now().toIso8601String(),
      'vehicleNumber': vehicleNumber,
      'location': effectiveLoc,
      'locationId': _currentUser?['locationId'] ?? (_currentUser?['location'] is Map ? _currentUser!['location']['id'] : null),
      'employeeId': _currentUser?['employeeId'] ?? _currentUser?['id'],
      'employeeName': _currentUser?['name'],
      'creatorRole': _currentUser?['role'],
      'receiptImage': receiptImage,
      'receiptUrl': receiptUrl ?? (receiptImage != null && receiptImage.isNotEmpty ? receiptImage : 'https://devmotors-assets.s3.amazonaws.com/receipts/bill.png'),
      'receiptFileName': receiptFileName ?? 'receipt.jpg',
    });

    final res = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $t',
      },
      body: body,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body);
      final rawData = decoded['data'] ?? decoded;
      if (rawData is Map) {
        final expMap = Map<String, dynamic>.from(rawData);
        if (_currentUser != null) {
          expMap.putIfAbsent('employee', () => _currentUser);
          expMap.putIfAbsent('employeeName', () => _currentUser!['name']);
          expMap.putIfAbsent('employeeId', () => _currentUser!['employeeId'] ?? _currentUser!['id']);
          expMap.putIfAbsent('creatorRole', () => _currentUser!['role']);
          if (effectiveLoc != null) expMap.putIfAbsent('location', () => effectiveLoc);
        }
        return expMap;
      }
      return Map<String, dynamic>.from(rawData);
    } else {
      throw Exception('Failed to create: ${res.body}');
    }
  }

  // 7. UPDATE EXPENSE
  static Future<Map<String, dynamic>> updateExpense({
    required String expenseId,
    String? category,
    required double amount,
    required String description,
    String? vehicleNumber,
    String? receiptImage,
  }) async {
    final t = await getToken();
    final body = jsonEncode({
      'amount': amount,
      'description': description,
      if (category != null && category.isNotEmpty) 'category': category,
      if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      if (receiptImage != null && receiptImage.isNotEmpty) ...{
        'receiptImage': receiptImage,
        'receiptUrl': receiptImage,
      },
    });

    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }

      // Fallback to PUT
      final resPut = await http.put(
        Uri.parse('$baseUrl/expenses/$expenseId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: body,
      );
      if (resPut.statusCode == 200 || resPut.statusCode == 201) {
        return jsonDecode(resPut.body);
      }
    } catch (_) {}

    return {'success': true};
  }

  // 8. PROCESS APPROVAL
  static Future<dynamic> processApproval({
    required String expenseId,
    required String action,
    double? approvedAmount,
    double? newAmount,
    String? comments,
    String? remarks,
    String? paymentMode,
  }) async {
    final t = await getToken();
    final finalAmount = approvedAmount ?? newAmount;
    final finalComments = comments ?? remarks;

    String backendAction = action;
    final act = action.toUpperCase();
    if (act.contains('REJECT')) {
      backendAction = 'REJECT';
    } else if (act.contains('PAY') || act.contains('DISBURSE') || act.contains('SETTLE')) {
      backendAction = 'PAY';
    } else if (act.contains('APPROVED_1') || act.contains('LEVEL_1')) {
      backendAction = 'APPROVED_1';
    } else if (act.contains('APPROVED_2') || act.contains('LEVEL_2')) {
      backendAction = 'APPROVED_2';
    } else {
      final role = (_currentUser?['role'] ?? '').toString().toUpperCase();
      if (role == 'MANAGER') {
        backendAction = 'APPROVED_1';
      } else if (role == 'OWNER') {
        backendAction = 'APPROVED_2';
      } else {
        backendAction = 'APPROVE';
      }
    }

    final body = jsonEncode({
      'action': backendAction,
      if (finalAmount != null) 'amount': finalAmount,
      if (finalComments != null && finalComments.isNotEmpty) 'comments': finalComments,
      if (paymentMode != null) 'paymentMode': paymentMode,
    });

    try {
      // Primary backend route: POST /expenses/:id/approval
      final res = await http.post(
        Uri.parse('$baseUrl/expenses/$expenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }

      // Fallback route: PUT /expenses/:id/approval
      final resPut = await http.put(
        Uri.parse('$baseUrl/expenses/$expenseId/approval'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: body,
      );
      if (resPut.statusCode == 200 || resPut.statusCode == 201) {
        return jsonDecode(resPut.body);
      }
    } catch (_) {}

    return {'success': false, 'message': 'Failed to process approval'};
  }

  // 9. APPROVE EXPENSE
  static Future<bool> approveExpense(String id, {String? comments, double? amount}) async {
    final res = await processApproval(expenseId: id, action: 'APPROVE', comments: comments, approvedAmount: amount);
    return res is Map && (res['success'] == true || res['data'] != null);
  }

  // 10. PAY EXPENSE
  static Future<bool> payExpense(String id, {String? paymentMode, String? comments}) async {
    final res = await processApproval(expenseId: id, action: 'PAY', paymentMode: paymentMode, comments: comments);
    return res is Map && (res['success'] == true || res['data'] != null);
  }

  // 11. REJECT EXPENSE
  static Future<bool> rejectExpense(String id, {required String reason}) async {
    final res = await processApproval(expenseId: id, action: 'REJECT', comments: reason, remarks: reason);
    return res is Map && (res['success'] == true || res['data'] != null);
  }

  // 12. DELETE EXPENSE
  static Future<bool> deleteExpense(String id) async {
    final t = await getToken();
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
      );
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // 13. LOGOUT
  static Future<void> logout() async {
    _token = null;
    _currentUser = null;
    AuthProvider().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user');
  }

  // 14. CREATE STAFF MEMBER
  static Future<Map<String, dynamic>> createStaffMember({
    required String employeeId,
    required String name,
    required String password,
    required String role,
    String? phone,
    String? branch,
    String? locationId,
  }) async {
    final t = await getToken();
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/users/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $t',
        },
        body: jsonEncode({
          'employeeId': employeeId,
          'name': name,
          'password': password,
          'role': role,
          'phone': phone,
          'branch': branch ?? 'Aligarh',
          'locationId': locationId,
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
      if (res.body.isNotEmpty) {
        try {
          final err = jsonDecode(res.body);
          return {'success': false, 'message': err['message'] ?? 'Failed to create user'};
        } catch (_) {}
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
    return {'success': true, 'message': 'Staff member created successfully'};
  }

  // 15. GET EXPENSE TIMELINE
  static Future<List<dynamic>> getExpenseTimeline(String expenseId) async {
    final t = await getToken();
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/expenses/$expenseId/timeline'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List) return decoded['data'];
      }
    } catch (_) {}
    return [];
  }

  // 16. NOTIFICATIONS API
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final t = await getToken();
    if (t.isEmpty) return [];
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded['data'] is List) {
          return List<Map<String, dynamic>>.from(
            (decoded['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> markNotificationRead(String notificationId) async {
    final t = await getToken();
    if (t.isEmpty) return false;
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> markAllNotificationsRead() async {
    final t = await getToken();
    if (t.isEmpty) return false;
    try {
      final res = await http.patch(
        Uri.parse('$baseUrl/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> clearAllNotifications() async {
    final t = await getToken();
    if (t.isEmpty) return false;
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

