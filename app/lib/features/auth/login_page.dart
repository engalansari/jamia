import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/localization/app_strings.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_profile_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userProfileService = UserProfileService();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final strings = context.strings;

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final credential = await _authService.signInWithUsernameAndPassword(
        username: _usernameController.text,
        password: _passwordController.text,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw _LoginFailure(strings.loginFailed);
      }

      final appUser = await _userProfileService.getUser(firebaseUser.uid);
      if (appUser == null) {
        await _authService.signOut();
        throw _LoginFailure(strings.accountNotReady);
      }

      if (!appUser.isActive) {
        await _authService.signOut();
        throw _LoginFailure(strings.accountDisabled);
      }

      await _userProfileService.updateLastLogin(firebaseUser.uid);
    } on FirebaseAuthException catch (error) {
      _showError(_messageForFirebaseAuthError(error));
    } on _LoginFailure catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError(strings.loginFailed);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorText = message);
  }

  String _messageForFirebaseAuthError(FirebaseAuthException error) {
    final strings = context.strings;
    switch (error.code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return strings.invalidCredentials;
      case 'user-disabled':
        return strings.accountDisabled;
      case 'network-request-failed':
        return strings.networkFailed;
      default:
        return strings.loginFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = context.strings;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.shopping_basket,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.loginSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ).copyWith(labelText: strings.username),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return strings.enterUsername;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onFieldSubmitted: (_) => _isSubmitting ? null : _submit(),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: strings.password,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? strings.showPassword
                              : strings.hidePassword,
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings.enterPassword;
                        }
                        return null;
                      },
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _errorText!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(strings.signIn),
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

class _LoginFailure implements Exception {
  const _LoginFailure(this.message);

  final String message;
}
