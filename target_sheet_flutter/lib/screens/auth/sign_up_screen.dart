import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';

const _colText   = Color(0xFF111827);
const _colText2  = Color(0xFF6B7280);
const _colBg     = Color(0xFFF7F2E8);
const _colBorder = Color(0xFFE5E7EB);
const _colNavBg  = Color(0xFFEDE8DC);
const _colAccent = Color(0xFFBA7517);

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({
    super.key,
    required this.onSignedUp,
    required this.onSignIn,
  });

  final VoidCallback onSignedUp;
  final VoidCallback onSignIn;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Display name is required.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    await ref.read(authProvider.notifier).signUp(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      name,
    );
    if (!mounted) return;
    final auth = ref.read(authProvider);
    auth.when(
      data: (s) {
        if (s.status == AuthStatus.signedIn) {
          setFirstRunDone(offline: false).then((_) => widget.onSignedUp());
        } else {
          setState(() { _loading = false; _error = 'Sign-up failed.'; });
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
        title: const Text('Create Account',
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
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 12),
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
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: widget.onSignIn,
                  child: const Text('Already have an account? Sign in',
                      style: TextStyle(color: _colText2, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
