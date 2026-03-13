import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/auth_repository.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _phoneController = TextEditingController(text: '+27');
  final _codeController = TextEditingController();

  String? _verificationId;
  String? _errorMessage;
  String? _infoMessage;
  bool _isSubmitting = false;

  bool get _isAwaitingCode => _verificationId != null;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in to Opportunity Radar',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use your phone number to access nearby work opportunities or post a task for local help.',
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isAwaitingCode && !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        hintText: '+27 82 123 4567',
                      ),
                    ),
                    if (_isAwaitingCode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          hintText: '123456',
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    if (_infoMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(_infoMessage!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : _isAwaitingCode
                              ? _verifyCode
                              : _sendCode,
                      child: Text(_isAwaitingCode ? 'Verify code' : 'Send code'),
                    ),
                    if (_isAwaitingCode) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isSubmitting ? null : _resetFlow,
                        child: const Text('Use a different number'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Enter a phone number before requesting a code.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final challenge = await ref.read(authRepositoryProvider).sendOtp(phoneNumber);
      if (!mounted) {
        return;
      }

      setState(() {
        _verificationId = challenge.verificationId;
        _infoMessage = challenge.autoVerified
            ? 'Your number was verified automatically.'
            : 'A verification code has been sent to your phone.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      return;
    }

    final smsCode = _codeController.text.trim();
    if (smsCode.length < 6) {
      setState(() {
        _errorMessage = 'Enter the 6-digit verification code.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      await ref.read(authRepositoryProvider).verifyOtp(
            verificationId: verificationId,
            smsCode: smsCode,
          );
      if (!mounted) {
        return;
      }

      setState(() {
        _infoMessage = 'Phone number verified successfully.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _resetFlow() {
    setState(() {
      _verificationId = null;
      _codeController.clear();
      _errorMessage = null;
      _infoMessage = null;
    });
  }
}
