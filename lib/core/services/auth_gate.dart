import 'package:flutter/material.dart';
import 'auth_api_service.dart';
import '../routes/app_routes.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isAuth = await AuthApiService.instance.isAuthenticated();
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isAuthenticated) {
      // Navigate to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      // Navigate to auth
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }
}