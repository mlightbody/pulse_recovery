import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';

class VerifyEmailWidget extends StatefulWidget {
  const VerifyEmailWidget({super.key});

  static String routeName = 'VerifyEmail';
  static String routePath = '/verifyEmail';

  @override
  State<VerifyEmailWidget> createState() => _VerifyEmailWidgetState();
}

class _VerifyEmailWidgetState extends State<VerifyEmailWidget> {
  bool _isSending = false;
  bool _isChecking = false;
  String? _message;

  Future<void> _resendEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      setState(() {
        _message = 'Verification email sent.';
      });
    } catch (e) {
      setState(() {
        _message = 'Failed to send email: $e';
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null && user.emailVerified) {
        setState(() {
          _message = 'Email verified!';
        });

        if (!mounted) return;
        context.go('/');
      } else {
        setState(() {
          _message = 'Still not verified. Please check your email.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error checking verification: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mark_email_read, size: 64),
                const SizedBox(height: 24),
                const Text(
                  'Verify your email',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'We’ve sent a verification link to:\n$email',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_message != null)
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isChecking ? null : _checkVerification,
                  child: _isChecking
                      ? const CircularProgressIndicator()
                      : const Text('I’ve verified my email'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isSending ? null : _resendEmail,
                  child: _isSending
                      ? const CircularProgressIndicator()
                      : const Text('Resend email'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _logout,
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}