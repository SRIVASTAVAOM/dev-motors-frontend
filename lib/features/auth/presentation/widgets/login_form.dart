import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/router/role_router.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    final empId = _employeeIdController.text.trim();
    final pwd = _passwordController.text.trim();

    if (empId.isEmpty || pwd.isEmpty) {
      setState(() => _errorMessage = 'Please enter both Employee ID and Password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.login(empId, pwd);

      // Extract role with multiple fallbacks
      String role = (res['data']?['user']?['role'] ?? 
                     res['user']?['role'] ?? 
                     res['data']?['role'] ?? 
                     res['role'] ?? 
                     '').toString().trim();

      // If backend sends empty role, infer from employeeId prefix
      if (role.isEmpty) {
        if (empId.startsWith('OWN') || empId.startsWith('owner')) {
          role = 'OWNER';
        } else if (empId.startsWith('MGR') || empId.contains('manager') || empId.endsWith('_gm') || empId.endsWith('_sm')) {
          role = 'MANAGER';
        } else if (empId.startsWith('CASH') || empId.contains('cashier')) {
          role = 'CASHIER';
        } else {
          role = 'EMPLOYEE';
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoleRouter.getDashboardForRole(role),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xffFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, size: 18, color: Color(0xffDC2626)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xffDC2626), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          const Text("Employee ID", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _employeeIdController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'Enter your Employee ID',
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
          const SizedBox(height: 16),

          const Text("Password", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff334155))),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            decoration: InputDecoration(
              hintText: 'Enter your password',
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
          const SizedBox(height: 20),

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
                        Text('Sign In to Portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


