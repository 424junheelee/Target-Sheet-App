import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import '../../providers/options_provider.dart';
import '../../providers/session_provider.dart';
import '../../rendering/graph_painter.dart';
import 'target_canvas.dart';

// Colour palette (constants.py)
const _colAccent  = Color(0xFFBA7517);
const _colText    = Color(0xFF111827);
const _colText2   = Color(0xFF6B7280);
const _colBg      = Color(0xFFF7F2E8);
const _colBg2     = Color(0xFFF7F2E8);
const _colBorder  = Color(0xFFE5E7EB);
const _colNavBg   = Color(0xFFEDE8DC);
const _colRecBg   = Color(0xFFFEFBF0);

String _fmtScore(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class ShootScreen extends ConsumerWidget {
  const ShootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final face = session.face;
    final isWide = MediaQuery.sizeOf(context).width > 600;

    final options = ref.watch(optionsProvider);

    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: Text(face.label,
            style: const TextStyle(color: _colText, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            color: _colText2,
            tooltip: 'Scorecards',
            onPressed: () => context.push('/scorecards'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _colBorder),
        ),
      ),
      body: isWide
          ? _WideLayout(session: session, showGraphs: options.showGraphs)
          : _NarrowLayout(session: session),
    );
  }
}

// ── Wide layout: target + graphs on left, controls on right ──────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.session, required this.showGraphs});
  final ShootSessionState session;
  final bool showGraphs;

  @override
  Widget build(BuildContext context) {
    final series = graphSeries(session.shots, session.moaMm);
    final maxShots = 12; // shoot_len(10) + 2 sighters

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Expanded(child: TargetCanvas()),
                    // Elevation graph strip (right of target)
                    if (showGraphs)
                      SizedBox(
                        width: 128,
                        child: CustomPaint(
                          painter: ElevGraphPainter(
                            series: series,
                            maxShots: maxShots,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Wind graph strip (below target)
              if (showGraphs)
                SizedBox(
                  height: 116,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: WindGraphPainter(
                      series: series,
                      maxShots: maxShots,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(width: 1, color: _colBorder),
        SizedBox(
          width: 300,
          child: _ControlPanel(session: session),
        ),
      ],
    );
  }
}

// ── Narrow layout: target on top, scorecard tab below ─────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.session});
  final ShootSessionState session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Expanded(flex: 3, child: TargetCanvas()),
        Container(height: 1, color: _colBorder),
        Expanded(flex: 2, child: _ControlPanel(session: session)),
      ],
    );
  }
}

// ── Control panel ─────────────────────────────────────────────────────────────

class _ControlPanel extends ConsumerWidget {
  const _ControlPanel({required this.session});
  final ShootSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(optionsProvider);
    final notifier = ref.read(sessionProvider.notifier);
    final total = notifier.total;
    final nextType = session.nextType;
    final nextLabel = switch (nextType) {
      ShotType.sighterA => 'Next: Sighter A',
      ShotType.sighterB => 'Next: Sighter B',
      ShotType.scored   => 'Next: Shot ${total.n + 1}',
      null              => 'String complete',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score row
          Row(
            children: [
              Expanded(
                child: Text(nextLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _colText)),
              ),
              Text(_fmtScore(total.tot),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                      color: _colText)),
              if (total.v > 0)
                Text('  v${total.v}',
                    style: const TextStyle(
                        fontFamily: 'Courier', color: _colText2)),
              const SizedBox(width: 8),
              Text('${total.n}/${session.shootLen}',
                  style: const TextStyle(color: _colText2, fontSize: 12)),
            ],
          ),
          const Divider(color: _colBorder),

          // Dial-to recommendation
          if (session.shots.isNotEmpty && options.showRec) ...[
            _DialToRow(session: session),
            const Divider(color: _colBorder),
          ],

          // Wind / elev dials
          _DialRow(session: session),
          const Divider(color: _colBorder),

          // Call buttons
          _CallRow(shots: session.shots),
          const Divider(color: _colBorder),

          // Conversion selector (shown after second shot, before chosen)
          if (session.shots.length >= 2 && !session.conversionChosen)
            _ConversionRow(session: session),

          // Action buttons
          Row(
            children: [
              OutlinedButton(
                onPressed:
                    session.shots.isEmpty ? null : notifier.undo,
                child: const Text('Undo'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed:
                    session.shots.isEmpty ? null : notifier.discard,
                style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFA32D2D)),
                child: const Text('Discard'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: session.shots.isEmpty
                ? null
                : () async {
                    final ctrl = TextEditingController();
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Save string'),
                        content: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Target number (optional)',
                          ),
                          autofocus: true,
                          onSubmitted: (_) => Navigator.pop(context, true),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true) return;
                    await notifier.commitString(
                        targetNumber: ctrl.text.trim());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('String saved'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _colAccent,
              foregroundColor: const Color(0xFFFFFFFF),
            ),
            child: const Text('Commit String'),
          ),
        ],
      ),
    );
  }
}

// ── Dial-to recommendation row ────────────────────────────────────────────────

class _DialToRow extends ConsumerWidget {
  const _DialToRow({required this.session});
  final ShootSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = dialToRecommendation(
      shots: session.shots,
      moaMm: session.moaMm,
      currentWind: session.windMoa,
      currentElev: session.elevMoa,
    );
    if (rec == null) return const SizedBox.shrink();

    return Container(
      color: _colRecBg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          const Text('Dial to:',
              style: TextStyle(color: _colText2, fontSize: 12)),
          const SizedBox(width: 8),
          const Text('W', style: TextStyle(color: _colText2, fontSize: 12)),
          const SizedBox(width: 4),
          Text(windLabel(rec.w),
              style: const TextStyle(
                  color: _colAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
          const SizedBox(width: 8),
          const Text('E', style: TextStyle(color: _colText2, fontSize: 12)),
          const SizedBox(width: 4),
          Text(elevLabel(rec.e),
              style: const TextStyle(
                  color: _colAccent,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
          const Spacer(),
          TextButton(
            onPressed: () {
              final n = ref.read(sessionProvider.notifier);
              // Apply: set wind and elev to the recommendation
              final diff = rec.w - ref.read(sessionProvider).windMoa;
              final steps = (diff / 0.25).round();
              for (var i = 0; i < steps.abs(); i++) {
                n.adjustWind(steps > 0 ? 1 : -1);
              }
              final eDiff = rec.e - ref.read(sessionProvider).elevMoa;
              final eSteps = (eDiff / 0.25).round();
              for (var i = 0; i < eSteps.abs(); i++) {
                n.adjustElev(eSteps > 0 ? 1 : -1);
              }
            },
            child: const Text('Apply',
                style: TextStyle(color: _colAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Wind/elev dial row ────────────────────────────────────────────────────────

class _DialRow extends ConsumerWidget {
  const _DialRow({required this.session});
  final ShootSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(sessionProvider.notifier);
    return Row(
      children: [
        _DialControl(
          label: 'Wind',
          value: windLabel(session.windMoa),
          onDec: () => n.adjustWind(-1),
          onInc: () => n.adjustWind(1),
          decIcon: '−',
          incIcon: '+',
        ),
        Container(width: 1, height: 40, color: _colBorder, margin: const EdgeInsets.symmetric(horizontal: 8)),
        _DialControl(
          label: 'Elev',
          value: elevLabel(session.elevMoa),
          onDec: () => n.adjustElev(-1),
          onInc: () => n.adjustElev(1),
          decIcon: '↓',
          incIcon: '↑',
        ),
      ],
    );
  }
}

class _DialControl extends StatelessWidget {
  const _DialControl({
    required this.label,
    required this.value,
    required this.onDec,
    required this.onInc,
    required this.decIcon,
    required this.incIcon,
  });

  final String label;
  final String value;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final String decIcon;
  final String incIcon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(color: _colText2, fontSize: 10)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onDec,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Text(decIcon,
                    style: const TextStyle(fontSize: 16, color: _colText)),
              ),
              Expanded(
                child: Center(
                  child: Text(value,
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          color: _colText2,
                          fontSize: 13)),
                ),
              ),
              IconButton(
                onPressed: onInc,
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Text(incIcon,
                    style: const TextStyle(fontSize: 16, color: _colText)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Call buttons ──────────────────────────────────────────────────────────────

class _CallRow extends ConsumerWidget {
  const _CallRow({required this.shots});
  final List<ScoredShot> shots;

  static const _calls = [
    ('pull-high',  '↑'),
    ('pull-left',  '←'),
    ('good',       '✓'),
    ('pull-right', '→'),
    ('pull-low',   '↓'),
    ('bad',        '✕'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cur = shots.isEmpty ? null : shots.last.call;
    final hasShots = shots.isNotEmpty;
    return Row(
      children: [
        for (final (key, glyph) in _calls)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: OutlinedButton(
                onPressed: hasShots
                    ? () => ref.read(sessionProvider.notifier).setCall(key)
                    : null,
                style: OutlinedButton.styleFrom(
                  backgroundColor: cur == key
                      ? (key == 'good'
                          ? const Color(0xFFEAF3DE)
                          : key == 'bad'
                              ? const Color(0xFFFCEBEB)
                              : _colBg2)
                      : _colBg2,
                  minimumSize: const Size(0, 36),
                  padding: EdgeInsets.zero,
                ),
                child: Text(glyph),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Conversion selector ───────────────────────────────────────────────────────

class _ConversionRow extends ConsumerWidget {
  const _ConversionRow({required this.session});
  final ShootSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(sessionProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('CONVERT SIGHTERS?',
            textAlign: TextAlign.center,
            style: TextStyle(color: _colText2, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            for (final (cv, label) in [
              (Conversion.none, 'None'),
              (Conversion.b,    'Score 1=B'),
              (Conversion.ab,   'Score 1=A,2=B'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    onPressed: () => n.setConversion(cv),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: session.conversion == cv
                          ? _colText
                          : _colBg,
                      foregroundColor: session.conversion == cv
                          ? const Color(0xFFFFFFFF)
                          : _colText2,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    child: Text(label),
                  ),
                ),
              ),
          ],
        ),
        const Divider(color: _colBorder),
      ],
    );
  }
}
