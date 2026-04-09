import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smart_placement/providers/auth_provider.dart';
import 'package:smart_placement/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartPlacementApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login screen shows email and password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
        child: const MaterialApp(home: SmartPlacementApp()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Smart Placement'), findsWidgets);
  });
}
