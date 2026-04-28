import 'package:flutter/material.dart';
import '../core/token_storage.dart';
import 'home_page.dart';
import 'worker_main_layout.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Future<Map<String, dynamic>> _checkSession() async {
    final token = await TokenStorage().getToken();
    if (token != null && token.isNotEmpty) {
      final role = await AuthService().getUserRole();
      return {'hasSession': true, 'role': role};
    }
    return {'hasSession': false};
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data?['hasSession'] == true) {
          final role = snapshot.data?['role'];
          if (role == 'technician' || role == 'worker') {
            return const WorkerMainLayout();
          }
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}