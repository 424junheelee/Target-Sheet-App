import 'dart:convert';

import 'package:flutter/material.dart';
// ignore: unnecessary_import
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import '../../data/database.dart';
import '../../data/scorecard_repository.dart';
import '../../rendering/shot_painter.dart';
import '../../rendering/target_painter.dart';
import '../../rendering/view_controller.dart';

const _colAccent  = Color(0xFFBA7517);
const _colText    = Color(0xFF111827);
const _colText2   = Color(0xFF6B7280);
const _colBg      = Color(0xFFF7F2E8);
const _colBorder  = Color(0xFFE5E7EB);
const _colNavBg   = Color(0xFFEDE8DC);

String _fmtScore(double v) =>
    v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

// autoDispose so each navigation to this screen loads fresh data.
final scorecardsProvider =
    FutureProvider.autoDispose<List<({Scorecard row, ScoreTotal total, String label})>>(
  (ref) async {
    final repo = ref.watch(scorecardRepositoryProvider);
    final rows = await repo.allScorecards();
    return rows.map((row) {
      final face = kTargetFaces[row.faceId];
      final shots = repo.decodeShotsFromRow(row);
      final total = calcTotal(shots, Conversion.values.byName(row.conversion), row.shootLen);
      return (row: row, total: total, label: face?.label ?? row.faceId);
    }).toList();
  },
);

class ScorecardListScreen extends ConsumerWidget {
  const ScorecardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scorecardsProvider);

    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: const Text('Saved Scorecards',
            style: TextStyle(color: _colText, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_outlined),
            color: _colText2,
            tooltip: 'Import from clipboard',
            onPressed: () => _importFromClipboard(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _colBorder),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Text('No saved scorecards yet.',
                  style: TextStyle(color: _colText2)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: cards.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: _colBorder),
            itemBuilder: (context, i) {
              final item = cards[i];
              final date = item.row.createdAt;
              final dateStr =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final tNum = item.row.targetNumber.isEmpty
                  ? ''
                  : '  #${item.row.targetNumber}';

              return ListTile(
                tileColor: _colBg,
                title: Text(
                  '${item.label}$tNum',
                  style: const TextStyle(
                      color: _colText, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(dateStr,
                    style: const TextStyle(color: _colText2, fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmtScore(item.total.tot),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                          color: _colText),
                    ),
                    if (item.total.v > 0)
                      Text(
                        ' v${item.total.v}',
                        style: const TextStyle(
                            fontFamily: 'Courier', color: _colText2),
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.download_outlined,
                          color: _colText2),
                      tooltip: 'Export JSON',
                      onPressed: () =>
                          _exportToClipboard(context, item.row),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFA32D2D)),
                      onPressed: () =>
                          _confirmDelete(context, ref, item.row.id),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => _AnalysisRoute(rowId: item.row.id),
                )),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete scorecard?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: Color(0xFFA32D2D)))),
        ],
      ),
    );
    if (ok == true) {
      final repo = ref.read(scorecardRepositoryProvider);
      await repo.deleteScorecard(id);
      ref.invalidate(scorecardsProvider);
    }
  }

  // ── Export ────────────────────────────────────────────────────────────────

  static String _exportJson(Scorecard row) {
    final shots = jsonDecode(row.shotsJson);
    return const JsonEncoder.withIndent('  ').convert({
      'version': row.formatVersion,
      'faceId': row.faceId,
      'conversion': row.conversion,
      'shootLen': row.shootLen,
      'targetNumber': row.targetNumber,
      'savedAt': row.savedAt,
      'shots': shots,
    });
  }

  Future<void> _exportToClipboard(
      BuildContext context, Scorecard row) async {
    final json = _exportJson(row);
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importFromClipboard(
      BuildContext context, WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Clipboard is empty')),
        );
      }
      return;
    }
    try {
      final j = jsonDecode(text) as Map<String, dynamic>;
      final faceId = j['faceId'] as String;
      if (!kTargetFaces.containsKey(faceId)) {
        throw FormatException('Unknown faceId: $faceId');
      }
      final face = kTargetFaces[faceId]!;
      final shotsList = j['shots'] as List<dynamic>;
      final shots = [
        for (final s in shotsList)
          _jsonToShot(s as Map<String, dynamic>, face.rings),
      ];
      final repo = ref.read(scorecardRepositoryProvider);
      await repo.saveScorecard(
        faceId: faceId,
        shots: shots,
        conversion:
            Conversion.values.byName(j['conversion'] as String? ?? 'none'),
        shootLen: (j['shootLen'] as int?) ?? 10,
        targetNumber: (j['targetNumber'] as String?) ?? '',
      );
      ref.invalidate(scorecardsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scorecard imported')),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  static ScoredShot _jsonToShot(
      Map<String, dynamic> j, List<Ring> rings) {
    final p = ModelPoint(
      (j['xMm'] as num).toDouble(),
      (j['yMm'] as num).toDouble(),
    );
    return ScoredShot(
      point: p,
      type: ShotType.values.byName(j['type'] as String),
      ring: scoreShot(p, rings),
      windMoa: (j['windMoa'] as num).toDouble(),
      elevMoa: (j['elevMoa'] as num).toDouble(),
      call: j['call'] as String?,
    );
  }
}

// Thin wrapper so we can navigate without go_router for now
class _AnalysisRoute extends StatelessWidget {
  const _AnalysisRoute({required this.rowId});
  final String rowId;

  @override
  Widget build(BuildContext context) {
    return _AnalysisScreenById(rowId: rowId);
  }
}

// ── Inline analysis screen (pulled from analysis_screen.dart via import) ──────
// We define a thin shell that analysis_screen.dart populates.

class _AnalysisScreenById extends ConsumerWidget {
  const _AnalysisScreenById({required this.rowId});
  final String rowId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scorecardsProvider);
    return async.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (cards) {
        final item = cards.where((c) => c.row.id == rowId).firstOrNull;
        if (item == null) {
          return const Scaffold(
              body: Center(child: Text('Scorecard not found.')));
        }
        final repo = ref.read(scorecardRepositoryProvider);
        final shots = repo.decodeShotsFromRow(item.row);
        return AnalysisContent(
          face: kTargetFaces[item.row.faceId]!,
          shots: shots,
          total: item.total,
          createdAt: item.row.createdAt,
          targetNumber: item.row.targetNumber,
        );
      },
    );
  }
}

// ── AnalysisContent ── reusable widget exposed so go_router can use it too ────

class AnalysisContent extends StatefulWidget {
  const AnalysisContent({
    super.key,
    required this.face,
    required this.shots,
    required this.total,
    required this.createdAt,
    this.targetNumber = '',
  });

  final TargetFace face;
  final List<ScoredShot> shots;
  final ScoreTotal total;
  final DateTime createdAt;
  final String targetNumber;

  @override
  State<AnalysisContent> createState() => _AnalysisContentState();
}

class _AnalysisContentState extends State<AnalysisContent> {
  final _vc = ViewController();

  @override
  Widget build(BuildContext context) {
    final moaMm = moaSizeAtYards(widget.face.effectiveYards);
    final stats = computeGroupStats(widget.shots, moaMm);
    final breakdown = callBreakdown(widget.shots);
    final series = graphSeries(widget.shots, moaMm);
    final labels = shotDisplayLabels(widget.shots, Conversion.none);

    final tNum = widget.targetNumber.isEmpty ? '' : '  #${widget.targetNumber}';
    final dateStr =
        '${widget.createdAt.year}-${widget.createdAt.month.toString().padLeft(2, '0')}-${widget.createdAt.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: Text('${widget.face.label}$tNum',
            style: const TextStyle(
                color: _colText, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _colBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Score + date header
            Row(
              children: [
                Text(dateStr,
                    style: const TextStyle(color: _colText2, fontSize: 13)),
                const Spacer(),
                Text(_fmtScore(widget.total.tot),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Courier',
                        color: _colText)),
                if (widget.total.v > 0)
                  Text('  v${widget.total.v}',
                      style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                          color: _colText2)),
              ],
            ),
            const SizedBox(height: 12),

            // Interactive target canvas
            _AnalysisCanvas(
              face: widget.face,
              moaMm: moaMm,
              shots: widget.shots,
              labels: labels,
              vc: _vc,
              onReset: () => setState(() => _vc.reset()),
            ),
            const SizedBox(height: 12),

            // Group stats
            if (stats.extremeSpreadMoa != null) ...[
              _StatRow(
                label: 'Extreme Spread',
                value: '${stats.extremeSpreadMoa!.toStringAsFixed(2)} MOA',
              ),
              _StatRow(
                label: 'Mean Radius',
                value: '${stats.meanRadiusMoa!.toStringAsFixed(2)} MOA',
              ),
              const SizedBox(height: 8),
            ],

            // Call breakdown
            if (breakdown.total > 0) ...[
              _StatRow(
                label: 'Calls',
                value:
                    '${breakdown.good} good · ${breakdown.pull} pull · ${breakdown.bad} bad',
              ),
              const SizedBox(height: 8),
            ],

            const Divider(color: _colBorder),

            // Shot table
            const SizedBox(height: 8),
            _ShotTable(shots: widget.shots, labels: labels),

            const SizedBox(height: 16),
            const Divider(color: _colBorder),

            // Graphs
            if (series.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Elevation Graph',
                  style: TextStyle(
                      color: _colText2,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SizedBox(
                height: 160,
                child: CustomPaint(
                  painter: _ElevAnalysisPainter(
                      series: series, maxShots: widget.shots.length),
                  size: Size.infinite,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Wind Graph',
                  style: TextStyle(
                      color: _colText2,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              SizedBox(
                height: 120,
                child: CustomPaint(
                  painter: _WindAnalysisPainter(
                      series: series, maxShots: widget.shots.length),
                  size: Size.infinite,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Interactive read-only target canvas for analysis ──────────────────────────

class _AnalysisCanvas extends StatefulWidget {
  const _AnalysisCanvas({
    required this.face,
    required this.moaMm,
    required this.shots,
    required this.labels,
    required this.vc,
    required this.onReset,
  });

  final TargetFace face;
  final double moaMm;
  final List<ScoredShot> shots;
  final List<String> labels;
  final ViewController vc;
  final VoidCallback onReset;

  @override
  State<_AnalysisCanvas> createState() => _AnalysisCanvasState();
}

class _AnalysisCanvasState extends State<_AnalysisCanvas> {
  double _scaleAtGestureStart = 1.0;
  Size _lastSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target',
            style: TextStyle(
                color: _colText2,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size =
                  Size(constraints.maxWidth, constraints.maxHeight);
              _lastSize = size;
              final transform =
                  widget.vc.buildTransform(size, widget.face);

              return GestureDetector(
                onScaleStart: (_) =>
                    _scaleAtGestureStart = widget.vc.zoom,
                onScaleUpdate: (d) {
                  setState(() {
                    if (d.pointerCount >= 2) {
                      final newZoom =
                          (_scaleAtGestureStart * d.scale).clamp(0.5, 8.0);
                      final factor = newZoom / widget.vc.zoom;
                      widget.vc.applyFocalZoom(
                          d.localFocalPoint, _lastSize, factor);
                    } else {
                      widget.vc.applyPanDelta(d.focalPointDelta);
                    }
                  });
                },
                child: Stack(
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        size: size,
                        painter: TargetFacePainter(
                          face: widget.face,
                          moaMm: widget.moaMm,
                          transform: transform,
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: size,
                      painter: ShotPainter(
                        shots: widget.shots,
                        labels: widget.labels,
                        transform: transform,
                        outerRingMm: widget.face.outerRing.radiusMm,
                        provisional: null,
                        conversion: Conversion.none,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.onReset,
            child: const Text('Reset view',
                style: TextStyle(color: _colText2, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

// ── Shot table ─────────────────────────────────────────────────────────────────

class _ShotTable extends StatelessWidget {
  const _ShotTable({required this.shots, required this.labels});
  final List<ScoredShot> shots;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(32),
        1: FixedColumnWidth(32),
        2: FlexColumnWidth(),
        3: FlexColumnWidth(),
        4: FixedColumnWidth(48),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _colBorder))),
          children: [
            _th('#'),
            _th('Sc'),
            _th('W'),
            _th('E'),
            _th('Call'),
          ],
        ),
        for (var i = 0; i < shots.length; i++)
          TableRow(
            children: [
              _td(labels[i]),
              _td(shots[i].label),
              _td(windLabel(shots[i].windMoa)),
              _td(elevLabel(shots[i].elevMoa)),
              _td(shots[i].call ?? ''),
            ],
          ),
      ],
    );
  }

  static Widget _th(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(t,
            style: const TextStyle(
                color: _colText2, fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
      );

  static Widget _td(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(t,
            style: const TextStyle(
                color: _colText, fontSize: 11, fontFamily: 'Courier'),
            textAlign: TextAlign.center),
      );
}

// ── Stat row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ',
              style: const TextStyle(color: _colText2, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: _colAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier')),
        ],
      ),
    );
  }
}

// ── Thin analysis graph painters (reuse graph_painter internals) ──────────────

class _ElevAnalysisPainter extends CustomPainter {
  const _ElevAnalysisPainter({required this.series, required this.maxShots});
  final List<({double wind, double elev})> series;
  final int maxShots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _colBg);
    if (series.isEmpty || maxShots < 1) return;

    const x0 = 28.0;
    final x1 = size.width - 8;
    const y0 = 12.0;
    final y1 = size.height - 16;
    final cy = (y0 + y1) / 2;
    const pxPerMoa = 24.0;

    final center = series.first.elev.roundToDouble();
    final nSide = ((cy - y0) / pxPerMoa).truncate();
    for (var off = -nSide; off <= nSide; off++) {
      final y = cy - off * pxPerMoa;
      final isCenter = off == 0;
      canvas.drawLine(
          Offset(x0, y),
          Offset(x1, y),
          Paint()
            ..color = isCenter
                ? const Color(0xFF888888)
                : const Color(0xFFE0E0E0)
            ..strokeWidth = isCenter ? 1.0 : 0.5);
      _drawText(canvas, '${(center + off).toInt()}', x0 - 4, y,
          rightAlign: true,
          color: isCenter ? _colAccent : _colText2,
          bold: isCenter);
    }

    final step = maxShots > 1 ? (x1 - x0) / (maxShots - 1) : x1 - x0;
    final pts = <Offset>[];
    for (var i = 0; i < series.length && i < maxShots; i++) {
      final y = (cy - (series[i].elev - center) * pxPerMoa).clamp(y0, y1);
      pts.add(Offset(x0 + i * step, y));
    }
    _drawSeriesLine(canvas, pts);
  }

  @override
  bool shouldRepaint(_ElevAnalysisPainter old) =>
      old.series != series || old.maxShots != maxShots;
}

class _WindAnalysisPainter extends CustomPainter {
  const _WindAnalysisPainter({required this.series, required this.maxShots});
  final List<({double wind, double elev})> series;
  final int maxShots;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _colBg);
    if (series.isEmpty || maxShots < 1) return;

    const x0 = 28.0;
    final x1 = size.width - 8;
    const y0 = 12.0;
    final y1 = size.height - 20;
    final cx = (x0 + x1) / 2;
    const pxPerMoa = 24.0;

    final center = series.first.wind.roundToDouble();
    final nSide = ((cx - x0) / pxPerMoa).truncate();
    for (var off = -nSide; off <= nSide; off++) {
      final x = cx + off * pxPerMoa;
      final isCenter = off == 0;
      canvas.drawLine(
          Offset(x, y0),
          Offset(x, y1),
          Paint()
            ..color = isCenter
                ? const Color(0xFF888888)
                : const Color(0xFFE0E0E0)
            ..strokeWidth = isCenter ? 1.0 : 0.5);
      _drawText(canvas, '${(center + off).toInt()}', x, y1 + 4,
          color: isCenter ? _colAccent : _colText2, bold: isCenter);
    }

    final step = maxShots > 1 ? (y1 - y0) / (maxShots - 1) : y1 - y0;
    final pts = <Offset>[];
    for (var i = 0; i < series.length && i < maxShots; i++) {
      final x = (cx + (series[i].wind - center) * pxPerMoa).clamp(x0, x1);
      pts.add(Offset(x, y0 + i * step));
    }
    _drawSeriesLine(canvas, pts);
  }

  @override
  bool shouldRepaint(_WindAnalysisPainter old) =>
      old.series != series || old.maxShots != maxShots;
}

void _drawSeriesLine(Canvas canvas, List<Offset> pts) {
  if (pts.length >= 2) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = _colAccent
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke);
  }
  for (final p in pts) {
    canvas.drawCircle(p, 3.0, Paint()..color = const Color(0xFFE24B4A));
  }
}

void _drawText(Canvas canvas, String text, double x, double y,
    {bool rightAlign = false, Color color = _colText2, bool bold = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: 8,
        fontFamily: 'Courier',
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final dx = rightAlign ? x - tp.width : x - tp.width / 2;
  tp.paint(canvas, Offset(dx, y - tp.height / 2));
}
