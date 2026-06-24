import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_provider.dart';
import '../../data/database.dart';
import '../../data/sight_preset_repository.dart';
import '../../providers/options_provider.dart';
import '../../providers/session_provider.dart';

const _colAccent = Color(0xFFBA7517);
const _colText   = Color(0xFF111827);
const _colText2  = Color(0xFF6B7280);
const _colBg     = Color(0xFFF7F2E8);
const _colBorder = Color(0xFFE5E7EB);
const _colNavBg  = Color(0xFFEDE8DC);

final _sightPresetsProvider =
    FutureProvider.autoDispose<List<SightPreset>>((ref) {
  final faceId = ref.watch(sessionProvider.select((s) => s.faceId));
  return ref.watch(sightPresetRepositoryProvider).presetsForFace(faceId);
});

class OptionsScreen extends ConsumerWidget {
  const OptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(optionsProvider);
    final session = ref.watch(sessionProvider);
    final presetsAsync = ref.watch(_sightPresetsProvider);
    final authAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: const Text('Options',
            style: TextStyle(color: _colText, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _colBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Shoot length ─────────────────────────────────────────────────
          const Text('DEFAULT SHOOT LENGTH',
              style: TextStyle(
                  color: _colText2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 10, label: Text('10 shots')),
              ButtonSegment(value: 15, label: Text('15 shots')),
            ],
            selected: {options.defaultShootLen},
            onSelectionChanged: (s) {
              ref.read(optionsProvider.notifier).setDefaultShootLen(s.first);
              ref.read(sessionProvider.notifier).setShootLen(s.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return _colAccent;
                return _colBg;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFFFFFFFF);
                }
                return _colText2;
              }),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: _colBorder),
          const SizedBox(height: 8),

          // ── Display toggles ──────────────────────────────────────────────
          const Text('DISPLAY',
              style: TextStyle(
                  color: _colText2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show dial-to suggestion',
                style: TextStyle(color: _colText, fontSize: 14)),
            value: options.showRec,
            activeThumbColor: _colAccent,
            onChanged: (v) =>
                ref.read(optionsProvider.notifier).setShowRec(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show wind & elevation graphs',
                style: TextStyle(color: _colText, fontSize: 14)),
            value: options.showGraphs,
            activeThumbColor: _colAccent,
            onChanged: (v) =>
                ref.read(optionsProvider.notifier).setShowGraphs(v),
          ),

          const SizedBox(height: 8),
          const Divider(color: _colBorder),
          const SizedBox(height: 8),

          // ── Sight presets ────────────────────────────────────────────────
          Row(
            children: [
              const Text('SIGHT PRESETS',
                  style: TextStyle(
                      color: _colText2,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(width: 8),
              Text('(${session.face.label})',
                  style: const TextStyle(color: _colText2, fontSize: 11)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _savePreset(context, ref, session),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save current'),
                style: TextButton.styleFrom(foregroundColor: _colAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),

          presetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
            data: (presets) {
              if (presets.isEmpty) {
                return const Text('No presets saved for this face yet.',
                    style: TextStyle(color: _colText2, fontSize: 13));
              }
              return Column(
                children: [
                  for (final preset in presets)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        preset.label.isEmpty
                            ? 'W ${_fmt(preset.windMoa)}  E ${_fmt(preset.elevMoa)}'
                            : preset.label,
                        style: const TextStyle(color: _colText, fontSize: 13),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (preset.label.isNotEmpty)
                            Text(
                              'W ${_fmt(preset.windMoa)}  E ${_fmt(preset.elevMoa)}',
                              style: const TextStyle(
                                  color: _colText2, fontSize: 11)),
                          if (preset.aperture.isNotEmpty)
                            Text('Aperture: ${preset.aperture}',
                                style: const TextStyle(
                                    color: _colText2, fontSize: 11)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => _applyPreset(ref, preset),
                            child: const Text('Apply',
                                style: TextStyle(color: _colAccent)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Color(0xFFA32D2D)),
                            onPressed: () => _deletePreset(ref, preset.id),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 8),
          const Divider(color: _colBorder),
          const SizedBox(height: 8),

          // ── Account ──────────────────────────────────────────────────────
          const Text('ACCOUNT',
              style: TextStyle(
                  color: _colText2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
          const SizedBox(height: 12),

          authAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(strokeWidth: 2))),
            error: (_, _) => const SizedBox.shrink(),
            data: (auth) {
              if (auth.status == AuthStatus.signedIn) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Signed in',
                              style: TextStyle(
                                  color: _colText2,
                                  fontSize: 11)),
                          if (auth.email != null)
                            Text(auth.email!,
                                style: const TextStyle(
                                    color: _colText, fontSize: 13)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).signOut(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFA32D2D),
                        side: const BorderSide(color: Color(0xFFA32D2D)),
                      ),
                      child: const Text('Sign out'),
                    ),
                  ],
                );
              }
              // offline or signedOut
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign in to sync your data across devices.',
                    style: TextStyle(color: _colText2, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.push('/auth/sign-in'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _colAccent,
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    child: const Text('Sign in / Create account'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == 0) return '0';
    final mag = v.abs();
    final s = mag == mag.truncateToDouble()
        ? mag.toStringAsFixed(0)
        : mag.toString();
    return v < 0 ? '${s}L' : '${s}R';
  }

  Future<void> _savePreset(
      BuildContext context, WidgetRef ref, ShootSessionState session) async {
    final labelCtrl    = TextEditingController();
    final apertureCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Save sight preset'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(hintText: 'Label (optional)'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: apertureCtrl,
              decoration:
                  const InputDecoration(hintText: 'Aperture (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sightPresetRepositoryProvider).savePreset(
            faceId: session.faceId,
            windMoa: session.windMoa,
            elevMoa: session.elevMoa,
            label: labelCtrl.text.trim(),
            aperture: apertureCtrl.text.trim(),
          );
      ref.invalidate(_sightPresetsProvider);
    }
  }

  void _applyPreset(WidgetRef ref, SightPreset preset) {
    final notifier = ref.read(sessionProvider.notifier);
    final session  = ref.read(sessionProvider);
    final wDiff  = preset.windMoa - session.windMoa;
    final wSteps = (wDiff / 0.25).round();
    for (var i = 0; i < wSteps.abs(); i++) {
      notifier.adjustWind(wSteps > 0 ? 1 : -1);
    }
    final eDiff  = preset.elevMoa - session.elevMoa;
    final eSteps = (eDiff / 0.25).round();
    for (var i = 0; i < eSteps.abs(); i++) {
      notifier.adjustElev(eSteps > 0 ? 1 : -1);
    }
  }

  Future<void> _deletePreset(WidgetRef ref, String id) async {
    await ref.read(sightPresetRepositoryProvider).deletePreset(id);
    ref.invalidate(_sightPresetsProvider);
  }
}
