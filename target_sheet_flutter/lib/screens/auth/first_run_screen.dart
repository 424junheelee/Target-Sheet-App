import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';

const _colText2  = Color(0xFF6B7280);
const _colBg     = Color(0xFFF7F2E8);
const _colBorder = Color(0xFFE5E7EB);
const _colAccent = Color(0xFFBA7517);

class FirstRunScreen extends ConsumerWidget {
  const FirstRunScreen({
    super.key,
    required this.onSignIn,
    required this.onOffline,
  });

  final VoidCallback onSignIn;
  final VoidCallback onOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: _colBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'TargetSheet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _colAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fullbore target-rifle scoring',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _colText2, fontSize: 13),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Sync your scorecards across devices with a free account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _colText2, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: onSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colAccent,
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Sign in / Create account',
                        style: TextStyle(fontSize: 15)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      await ref.read(authProvider.notifier).continueOffline();
                      onOffline();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _colBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Use offline',
                        style: TextStyle(fontSize: 15, color: _colText2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
