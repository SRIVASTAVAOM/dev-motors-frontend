import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../features/auth/presentation/pages/login_page.dart';
import '../../../../features/dashboard/presentation/pages/employee_dashboard.dart';
import '../../../../features/dashboard/presentation/pages/manager_dashboard.dart';
import '../../../../features/dashboard/presentation/pages/cashier_dashboard.dart';
import '../../../../features/dashboard/presentation/pages/owner_dashboard.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _navigateNext();
  }

  void _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final authProvider = AuthProvider();
    Widget targetPage = const LoginPage();

    final user = authProvider.user;
    final token = authProvider.token;

    if (token != null && token.isNotEmpty && user != null) {
      final role = (user['role'] ?? '').toString().toUpperCase();
      if (role == 'OWNER' || role == 'ADMIN') {
        targetPage = const OwnerDashboard();
      } else if (role == 'MANAGER') {
        targetPage = const ManagerDashboard();
      } else if (role == 'CASHIER') {
        targetPage = const CashierDashboard();
      } else {
        targetPage = const EmployeeDashboard();
      }
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => targetPage,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.asset(
              'assets/images/dev_motors_splash.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xffD32F2F)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
