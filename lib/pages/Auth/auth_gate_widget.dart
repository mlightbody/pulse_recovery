import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/pages/auth/login_register_widget.dart';
import '/pages/dashboard/dashboard_widget.dart';
import '/pages/auth/verify_email_widget.dart';

class AuthGateWidget extends StatelessWidget {
  const AuthGateWidget({super.key});

  // 🔥 REQUIRED for GoRouter (this was missing)
  static String routeName = 'AuthGate';
  static String routePath = '/authGate';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in → show login/register
        if (!snapshot.hasData) {
          return const LoginRegisterWidget();
        }

        // Logged in → go to dashboard
        final user = snapshot.data;

if (user != null && !user.emailVerified) {
  return VerifyEmailWidget();
}
        return const DashboardWidget();
      },
    );
  }
}