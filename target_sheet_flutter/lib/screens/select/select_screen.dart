import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:targetsheet_core/targetsheet_core.dart';

import '../../providers/options_provider.dart';
import '../../providers/session_provider.dart';

const _colText   = Color(0xFF111827);
const _colText2  = Color(0xFF6B7280);
const _colBg     = Color(0xFFF7F2E8);
const _colBorder = Color(0xFFE5E7EB);
const _colNavBg  = Color(0xFFEDE8DC);
const _colAccent = Color(0xFFBA7517);

// Faces grouped by standard string (prefix before first space)
Map<String, List<MapEntry<String, TargetFace>>> _grouped() {
  final groups = <String, List<MapEntry<String, TargetFace>>>{};
  for (final entry in kTargetFaces.entries) {
    // Group key: first word of distanceLabel or id prefix
    final key = entry.value.standard;
    groups.putIfAbsent(key, () => []).add(entry);
  }
  return groups;
}

class SelectScreen extends ConsumerWidget {
  const SelectScreen({super.key, required this.onSelected});

  /// Called with the chosen faceId so the caller can navigate to shoot.
  final void Function(String faceId) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(optionsProvider);
    final groups = _grouped();
    final standards = groups.keys.toList()..sort();

    return Scaffold(
      backgroundColor: _colBg,
      appBar: AppBar(
        backgroundColor: _colNavBg,
        title: const Text('Select Distance & Standard',
            style: TextStyle(color: _colText, fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _colBorder),
        ),
      ),
      body: Column(
        children: [
          // Shoot length selector at top
          Container(
            color: _colNavBg,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Shoot length: ',
                    style: TextStyle(color: _colText2, fontSize: 13)),
                for (final len in [10, 15])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$len shots'),
                      selected: options.defaultShootLen == len,
                      onSelected: (_) {
                        ref
                            .read(optionsProvider.notifier)
                            .setDefaultShootLen(len);
                        ref
                            .read(sessionProvider.notifier)
                            .setShootLen(len);
                      },
                      selectedColor: _colAccent,
                      labelStyle: TextStyle(
                        color: options.defaultShootLen == len
                            ? const Color(0xFFFFFFFF)
                            : _colText2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: _colBorder),

          // Face list grouped by standard
          Expanded(
            child: ListView(
              children: [
                for (final standard in standards) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      standard,
                      style: const TextStyle(
                        color: _colText2,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  for (final entry in groups[standard]!)
                    ListTile(
                      tileColor: _colBg,
                      title: Text(entry.value.label,
                          style: const TextStyle(
                              color: _colText, fontSize: 15)),
                      subtitle: Text(
                        entry.value.distanceLabel,
                        style:
                            const TextStyle(color: _colText2, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: _colText2),
                      onTap: () {
                        ref
                            .read(sessionProvider.notifier)
                            .setFace(entry.key);
                        onSelected(entry.key);
                      },
                    ),
                  const Divider(height: 1, color: _colBorder),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
