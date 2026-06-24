import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_provider.dart';
import '../../data/scorecard_repository.dart';
import '../../providers/session_provider.dart';

const _colText   = Color(0xFF111827);
const _colText2  = Color(0xFF6B7280);
const _colBg     = Color(0xFFF7F2E8);
const _colBorder = Color(0xFFE5E7EB);
const _colNavBg  = Color(0xFFEDE8DC);
const _colAccent = Color(0xFFBA7517);

/// True when a draft in-progress session exists in the DB.
final _hasDraftProvider = FutureProvider.autoDispose<bool>((ref) async {
  final draft = await ref.watch(scorecardRepositoryProvider).loadDraft();
  return draft != null;
});

class MenuScreen extends ConsumerWidget {
  const MenuScreen({
    super.key,
    required this.onNewString,
    required this.onScorecards,
    required this.onOptions,
    required this.onShoot,
  });

  final VoidCallback onNewString;
  final VoidCallback onScorecards;
  final VoidCallback onOptions;
  final VoidCallback onShoot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDraftAsync = ref.watch(_hasDraftProvider);
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: const Text('TargetSheet',
            style: TextStyle(
                color: _colText,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
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
                const SizedBox(height: 4),
                const Text(
                  'Fullbore target-rifle scoring',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _colText2, fontSize: 13),
                ),
                authAsync.maybeWhen(
                  data: (auth) => auth.status == AuthStatus.signedIn &&
                          auth.email != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            auth.email!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: _colText2, fontSize: 11),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 40),

                // Resume in-progress string if one was saved
                hasDraftAsync.maybeWhen(
                  data: (hasDraft) => hasDraft
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _MenuButton(
                              icon: Icons.restore,
                              label: 'Resume String',
                              onTap: () => _resumeDraft(context, ref),
                              primary: true,
                            ),
                            const SizedBox(height: 8),
                          ],
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),

                _MenuButton(
                  icon: Icons.my_location,
                  label: 'New String',
                  onTap: onNewString,
                  primary: !hasDraftAsync.maybeWhen(
                      data: (v) => v, orElse: () => false),
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  icon: Icons.list_alt,
                  label: 'Saved Scorecards',
                  onTap: onScorecards,
                ),
                const SizedBox(height: 12),
                _MenuButton(
                  icon: Icons.tune,
                  label: 'Options',
                  onTap: onOptions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _resumeDraft(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(scorecardRepositoryProvider);
    final draft = await repo.loadDraft();
    if (draft == null) return;
    final notifier = ref.read(sessionProvider.notifier);
    notifier.restoreFromDraft(
      faceId: draft.faceId,
      shots: draft.shots,
      conversion: draft.conversion,
      shootLen: draft.shootLen,
      windMoa: draft.windMoa,
      elevMoa: draft.elevMoa,
    );
    onShoot();
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: primary
          ? ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20),
              label: Text(label,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _colAccent,
                foregroundColor: const Color(0xFFFFFFFF),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 20, color: _colText2),
              label: Text(label,
                  style: const TextStyle(fontSize: 15, color: _colText)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _colBorder),
                backgroundColor: _colBg,
              ),
            ),
    );
  }
}
