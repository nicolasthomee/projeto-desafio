import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_integrador/main.dart';

void main() {
  testWidgets('App inicializa sem erros', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const IotApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
