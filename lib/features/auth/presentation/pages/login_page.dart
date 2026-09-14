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
  String? _selectedDemoRole;

  final List<Map<String, dynamic>> _demoRoles = [
    {
      'role': 'OWNER',
      'label': 'Owner',
      'name': 'Devendra Sharma',
      'empId': 'owner_dev_director',
      'icon': Icons.admin_panel_settings_rounded,
      'color': const Color(0xff7C3AED),
      'bgColor': const Color(0xffF5F3FF),
      'borderColor': const Color(0xffDDD6FE),
    },
    {
      'role': 'MANAGER',
      'label': 'Manager',
      'name': 'Arman (GM)',
      'empId': 'main_arman_gm',
      'icon': Icons.business_center_rounded,
      'color': const Color(0xff1D4ED8),
      'bgColor': const Color(0xffEFF6FF),
      'borderColor': const Color(0xffBFDBFE),
    },
    {
      'role': 'CASHIER',
      'label': 'Cashier',
      'name': 'Rakesh (Cashier)',
      'empId': 'main_rakesh_cashier',
      'icon': Icons.account_balance_wallet_rounded,
      'color': const Color(0xff059669),
      'bgColor': const Color(0xffECFDF5),
      'borderColor': const Color(0xffA7F3D0),
    },
    {
      'role': 'EMPLOYEE',
      'label': 'Employee',
      'name': 'Muneesh (BSM)',
      'empId': 'nexa_muneesh_bsm',
      'icon': Icons.person_rounded,
      'color': const Color(0xff0284C7),
      'bgColor': const Color(0xffF0F9FF),
      'borderColor': const Color(0xffBAE6FD),
    },
  ];

  void _selectDemoRole(Map<String, dynamic> demo) {
    setState(() {
      _selectedDemoRole = demo['role'];
      _idController.text = demo['empId'];
      _passController.text = 'password123';
    });
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(demo['icon'] as IconData, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text("${demo['label']} credentials loaded (${demo['name']})"),
          ],
        ),
        backgroundColor: demo['color'] as Color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _routeByRole(String role) {
    final r = role;
    Widget target;
    if (r == 'OWNER' || r == 'ADMIN') {
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
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text("Please enter Employee ID and Password"),
            ],
          ),
          backgroundColor: const Color(0xffDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
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
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(e.toString().replaceAll("Exception:", "").trim())),
              ],
            ),
            backgroundColor: const Color(0xffDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Color(0xff2563EB), size: 24),
            SizedBox(width: 10),
            Text("Reset Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff0F172A))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enter your registered Employee ID and new password:", style: TextStyle(fontSize: 13, color: Color(0xff64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: resetIdController,
              decoration: InputDecoration(
                labelText: "Employee ID",
                hintText: "e.g. main_arman_gm",
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xff64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              if (resetIdController.text.trim().isNotEmpty && resetPassController.text.trim().isNotEmpty) {
                await ApiService.forgotPassword(resetIdController.text.trim(), resetPassController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Password reset successful! Please login with your new credentials."),
                      backgroundColor: const Color(0xff059669),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            child: const Text("Update Password", style: TextStyle(fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- DEALERSHIP BRAND EMBLEM ---
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xff0F172A), Color(0xff1E3A8A)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff1E3A8A).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 38),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // --- DEALERSHIP TITLE & SUBTITLE ---
                  const Text(
                    "DEV MOTORS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Authorized Maruti Suzuki Dealership",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff2563EB),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // --- MULTI-BRANCH PILL BADGE ---
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF6FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xffBFDBFE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hub_outlined, size: 13, color: Color(0xff2563EB)),
                          SizedBox(width: 6),
                          Text(
                            "Aligarh • Khair • Atrauli • Iglas",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E40AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- MAIN LOGIN CARD ---
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xffE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff0F172A).withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1-TAP QUICK ROLE ACCESS BAR ---
                        Row(
                          children: [
                            const Icon(Icons.bolt_rounded, size: 16, color: Color(0xffD97706)),
                            const SizedBox(width: 6),
                            const Text(
                              "QUICK ROLE ACCESS (DEMO)",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Color(0xff64748B),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xffF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "1-Tap",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xff475569)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Role Selector Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _demoRoles.map((demo) {
                            final isSelected = _selectedDemoRole == demo['role'];
                            return InkWell(
                              onTap: () => _selectDemoRole(demo),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected ? (demo['color'] as Color).withValues(alpha: 0.12) : (demo['bgColor'] as Color),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? (demo['color'] as Color) : (demo['borderColor'] as Color),
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: (demo['color'] as Color).withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      demo['icon'] as IconData,
                                      size: 14,
                                      color: demo['color'] as Color,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      demo['label'] as String,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: demo['color'] as Color,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.check_circle_rounded, size: 12, color: demo['color'] as Color),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        const Divider(height: 1, color: Color(0xffF1F5F9)),
                        const SizedBox(height: 20),

                        // Employee ID Label & Input
                        const Text(
                          "Employee ID",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff334155)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _idController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: "e.g. owner_dev_director",
                            hintStyle: const TextStyle(color: Color(0xff94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xff64748B)),
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.8)),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Password Label & Input
                        const Text(
                          "Password",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff334155)),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: "Enter your password",
                            hintStyle: const TextStyle(color: Color(0xff94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xff64748B)),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xff64748B)),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xffF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffCBD5E1))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xffE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.8)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(fontSize: 12, color: Color(0xff2563EB), fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Sign In Submit Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xff1E40AF), Color(0xff2563EB)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff2563EB).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("Sign In to Portal", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ENTERPRISE SECURITY FOOTER ---
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: Color(0xff64748B)),
                      SizedBox(width: 6),
                      Text(
                        "256-Bit TLS Secured • Enterprise Governance Portal",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xff64748B)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Authorized Personnel Only • Dev Motors Management System",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Color(0xff94A3B8)),
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

