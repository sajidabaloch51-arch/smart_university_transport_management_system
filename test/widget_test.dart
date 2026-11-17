import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/providers/auth_provider.dart';

/// Smoke widget test without Firebase.initializeApp (full SUTMSApp needs it).
void main() {
  testWidgets('AuthProvider updates UI and role home matches guard',
      (WidgetTester tester) async {
    final auth = AuthProvider();
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: auth,
          builder: (_, __) => Text(auth.isAuthenticated ? 'in' : 'out'),
        ),
      ),
    );

    expect(find.text('out'), findsOneWidget);

    auth.setAuthenticated(true, role: 'admin', uid: 'admin_uid');
    await tester.pump();

    expect(find.text('in'), findsOneWidget);
    expect(AuthRouteGuard.homeForRole(auth.userRole), '/admin-dashboard');
  });
}
