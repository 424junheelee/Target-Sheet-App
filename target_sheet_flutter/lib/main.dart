import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: TargetSheetApp()));
}

class TargetSheetApp extends StatelessWidget {
  const TargetSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'TargetSheet',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text('TargetSheet')),
      ),
    );
  }
}
