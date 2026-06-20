import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/messaging_service.dart';
import '../../core/services/user_profile_service.dart';
import '../home/home_shell.dart';
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          return const LoginPage();
        }

        return _UserProfileGate(userId: firebaseUser.uid);
      },
    );
  }
}

class _UserProfileGate extends StatelessWidget {
  const _UserProfileGate({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: UserProfileService().watchUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScaffold();
        }

        final user = snapshot.data;
        if (user == null) {
          return _BlockedAccountScaffold(
            message:
                '\u0647\u0630\u0627 \u0627\u0644\u062d\u0633\u0627\u0628 \u063a\u064a\u0631 \u0645\u062c\u0647\u0632 \u062f\u0627\u062e\u0644 \u0627\u0644\u062a\u0637\u0628\u064a\u0642. \u062a\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u0645\u062f\u064a\u0631.',
          );
        }

        if (!user.isActive) {
          return _BlockedAccountScaffold(
            message:
                '\u062a\u0645 \u062a\u0639\u0637\u064a\u0644 \u0647\u0630\u0627 \u0627\u0644\u062d\u0633\u0627\u0628. \u062a\u0648\u0627\u0635\u0644 \u0645\u0639 \u0627\u0644\u0645\u062f\u064a\u0631.',
          );
        }

        return _MessagingRegistration(user: user);
      },
    );
  }
}

class _MessagingRegistration extends StatefulWidget {
  const _MessagingRegistration({required this.user});

  final AppUser user;

  @override
  State<_MessagingRegistration> createState() => _MessagingRegistrationState();
}

class _MessagingRegistrationState extends State<_MessagingRegistration> {
  var _isRegistered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isRegistered) return;
    _isRegistered = true;
    MessagingService().registerDevice(widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return HomeShell(currentUser: widget.user);
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _BlockedAccountScaffold extends StatelessWidget {
  const _BlockedAccountScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_person, size: 48),
                const SizedBox(height: 16),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: AuthService().signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    '\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u062e\u0631\u0648\u062c',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
