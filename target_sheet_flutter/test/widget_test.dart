import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target_sheet/main.dart';

void main() {
  testWidgets('app launches without error', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TargetSheetApp()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
