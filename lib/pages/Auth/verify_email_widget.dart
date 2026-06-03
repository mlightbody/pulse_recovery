import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

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
  bool _messageIsError = false;

  Future<void> _resendEmail() async {
    setState(() {
      _isSending = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _message = 'No signed-in user found. Please sign in again.';
          _messageIsError = true;
        });

        return;
      }

      await user.sendEmailVerification();

      if (!mounted) return;

      setState(() {
        _message =
            'Verification email sent. Please check your inbox and spam folder.';
        _messageIsError = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.message ?? 'Failed to send verification email.';
        _messageIsError = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Failed to send verification email: $e';
        _messageIsError = true;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _checkVerification() async {
    setState(() {
      _isChecking = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        context.goNamed(LoginRegisterWidget.routeName);
        return;
      }

      // Important: FirebaseAuth can hold stale user state.
      // Reload before checking emailVerified.
      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        if (!mounted) return;

        context.goNamed(DashboardWidget.routeName);
        return;
      }

      if (!mounted) return;

      setState(() {
        _message =
            'Your email is not verified yet. Please click the link in your email, check spam or junk if needed, then try again.';
        _messageIsError = true;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _message = e.message ?? 'Error checking verification status.';
        _messageIsError = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _message = 'Error checking verification status: $e';
        _messageIsError = true;
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    context.goNamed(LoginRegisterWidget.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.mark_email_read,
                      size: 72,
                      color: theme.primaryText,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Verify your email',
                      textAlign: TextAlign.center,
                      style: theme.headlineMedium.override(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'We’ve sent a verification link to:',
                      textAlign: TextAlign.center,
                      style: theme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: theme.bodyLarge.override(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please open the email and click the verification link. '
                      'If you don’t see it, check your spam or junk folder.',
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                        lineHeight: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Once verified, return here and tap the button below.',
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                        lineHeight: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_message != null) ...[
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.override(
                          color: _messageIsError ? theme.error : theme.primary,
                          lineHeight: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isChecking ? null : _checkVerification,
                        child: _isChecking
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('I’ve verified my email'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _isSending ? null : _resendEmail,
                      child: _isSending
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Resend email'),
                    ),
                    const SizedBox(height: 28),
                    TextButton(
                      onPressed: _logout,
                      child: const Text('Use a different email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}