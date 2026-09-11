import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../dashboard/presentation/pages/employee_dashboard.dart';
import '../../../dashboard/presentation/pages/manager_dashboard.dart';
import '../../../dashboard/presentation/pages/owner_dashboard.dart';
import '../../../dashboard/presentation/pages/cashier_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _idController = TextEditingController();
  final _passController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _routeByRole(String role) {
    final r = role;
    Widget target;
    if (r == 'OWNER') {
      target = const OwnerDashboard();
    } else if (r == 'MANAGER') {
      target = const ManagerDashboard();
    } else if (r == 'CASHIER') {
      target = const CashierDashboard();
    } else {
      target = const EmployeeDashboard();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => target));
  }

  Future<void> _handleLogin() async {
    final empId = _idController.text.trim();
    final pass = _passController.text.trim();

    if (empId.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter Employee ID and Password"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.login(empId, pass);
      final role = (res['data']?['role'] ?? res['user']?['role'] ?? res['data']?['user']?['role'] ?? res['role'] ?? 'EMPLOYEE').toString().toUpperCase();
      if (mounted) _routeByRole(role);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception:", "").trim()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetIdController = TextEditingController();
    final resetPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: resetIdController,
              decoration: const InputDecoration(labelText: "Employee ID", hintText: "e.g. main_arman_gm"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: resetPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2563EB), foregroundColor: Colors.white),
            onPressed: () async {
              if (resetIdController.text.trim().isNotEmpty && resetPassController.text.trim().isNotEmpty) {
                await ApiService.forgotPassword(resetIdController.text.trim(), resetPassController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password reset successful! Please login with your new credentials.")),
                  );
                }
              }
            },
            child: const Text("Update Password"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff2563EB),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xff2563EB).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.directions_car_filled, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Dev Motors",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xff0F172A)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Expense Management System",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xff64748B)),
                  ),
                  const SizedBox(height: 36),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Employee ID", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff334155))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _idController,
                          decoration: InputDecoration(
                            hintText: "Enter your Employee ID",
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xff94A3B8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xff334155))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: "Enter your Password",
                            prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Color(0xff94A3B8)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 20, color: const Color(0xff94A3B8)),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text("Forgot Password?", style: TextStyle(fontSize: 13, color: Color(0xff2563EB), fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text("Sign In", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
