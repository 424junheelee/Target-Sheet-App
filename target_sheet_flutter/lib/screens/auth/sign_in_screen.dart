import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';

const _colText   = Color(0xFF111827);
const _colBg     = Color(0xFFF7F2E8);
const _colBorder = Color(0xFFE5E7EB);
const _colNavBg  = Color(0xFFEDE8DC);
const _colAccent = Color(0xFFBA7517);

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({
    super.key,
    required this.onSignedIn,
    required this.onCreateAccount,
  });

  final VoidCallback onSignedIn;
  final VoidCallback onCreateAccount;

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    await ref.read(authProvider.notifier).signIn(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (!mounted) return;
    final auth = ref.read(authProvider);
    auth.when(
      data: (s) {
        if (s.status == AuthStatus.signedIn) {
          setFirstRunDone(offline: false).then((_) => widget.onSignedIn());
        } else {
          setState(() { _loading = false; _error = 'Sign-in failed.'; });
        }
      },
      error: (e, _) => setState(() { _loading = false; _error = e.toString(); }),
      loading: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: const Text('Sign In',
            style: TextStyle(color: _colText, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _colBorder),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  onSubmitted: (_) => _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFA32D2D), fontSize: 13)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _colAccent,
                    foregroundColor: const Color(0xFFFFFFFF),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onCreateAccount,
                  child: const Text('Create account',
                      style: TextStyle(color: _colAccent)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
