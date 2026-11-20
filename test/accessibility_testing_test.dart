import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sutms/models/student_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/providers/live_tracking_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/custom_textfield.dart';

/// Accessibility tests: readable labels, tap targets, large text scale,
/// and screen-reader-friendly status / recovery copy (no live Firebase).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AX-01 Role selection semantics', () {
    testWidgets('role cards are labeled buttons and meet tap-target guidelines',
        (tester) async {
      final auth = AuthProvider();
      final router = GoRouter(
        initialLocation: '/role-selection',
        routes: [
          GoRoute(
            path: '/role-selection',
            builder: (_, __) => const RoleSelectionScreen(),
          ),
          GoRoute(
            path: '/student-portal-entry',
            builder: (_, __) => const Scaffold(body: Text('STUDENT_ENTRY')),
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to SUTMS'), findsOneWidget);
      expect(find.text('Please select your role to continue'), findsOneWidget);

      // Screen reader can find each role by name.
      expect(find.bySemanticsLabel(RegExp('Student')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Bus Driver')), findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Administrator')), findsWidgets);

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();

      await tester.tap(find.text('Student'));
      await tester.pumpAndSettle();
      expect(find.text('STUDENT_ENTRY'), findsOneWidget);
    });
  });

  group('AX-02 Large text scale', () {
    testWidgets('role selection remains usable at textScale 1.5', (tester) async {
      final auth = AuthProvider();
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.5),
          ),
          child: ChangeNotifierProvider.value(
            value: auth,
            child: MaterialApp(
              home: const RoleSelectionScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Bus Driver'), findsOneWidget);
      expect(find.text('Administrator'), findsOneWidget);
    });
  });

  group('AX-03 Form field labels', () {
    testWidgets('CustomTextField exposes its label to semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: CustomTextField(
                labelText: 'Email Address',
                hintText: 'name@uog.edu.pk',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email Address'), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(
        find.bySemanticsLabel(RegExp('Email Address')),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('AX-04 Error recovery actions', () {
    testWidgets('Retry button is labeled and tappable', (tester) async {
      var retries = 0;
      StreamController<List<String>>? controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream.error(StateError('Please log in again to load data.')),
              streamFactory: () {
                retries++;
                controller?.close();
                controller = StreamController<List<String>>();
                controller!.add(const ['ok']);
                return controller!.stream;
              },
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'Nothing here',
              builder: (_, data) => Text(data.first),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Retry')), findsWidgets);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(retries, greaterThan(0));
      expect(find.text('ok'), findsOneWidget);

      await controller?.close();
    });
  });

  group('AX-05 Live tracking status language for AT', () {
    test('status labels avoid jargon and stay human-readable', () {
      final p = LiveTrackingProvider();
      expect(p.statusLabel, 'Select a route first');

      final assigned = StudentModel(
        uid: 's1',
        name: 'Sara Ali',
        email: 'sara@uog.edu.pk',
        phone: '03001234567',
        role: 'student',
        regNumber: '19-UOG-001',
        department: 'CS',
        rollNo: '01',
        assignedRouteId: 'route-1',
        assignedBusId: 'bus-1',
      );
      p.seedForUiTest(student: assigned);
      expect(p.statusLabel, 'Bus is not currently active');

      p.seedForUiTest(
        student: assigned,
        trip: const TripModel(
          id: 't1',
          busId: 'bus-1',
          driverId: 'd1',
          routeId: 'route-1',
          status: 'ACTIVE',
        ),
      );
      expect(p.statusLabel, "Waiting for the driver's location...");

      for (final label in [
        'Select a route first',
        'Bus is not currently active',
        "Waiting for the driver's location...",
        'Location delayed',
        'Live',
        'Trip ended',
      ]) {
        final lower = label.toLowerCase();
        expect(lower, isNot(contains('null')));
        expect(lower, isNot(contains('exception')));
        expect(lower, isNot(contains('firebase')));
        expect(lower, isNot(contains('firestore')));
      }
    });
  });
}
