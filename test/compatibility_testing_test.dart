import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/screens/shared/role_selection_screen.dart';
import 'package:sutms/services/maps_service.dart';
import 'package:sutms/widgets/async_state_view.dart';
import 'package:sutms/widgets/osm_map_view.dart';

/// Compatibility tests: layouts across phone/tablet sizes, text scale,
/// and platform/package contracts (OSM stack, no Google Maps SDK).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sizes = <(String, Size)>[
    ('iPhone SE-ish', const Size(320, 568)),
    ('common Android', const Size(360, 800)),
    ('Pixel-ish', const Size(411, 891)),
    ('small tablet', const Size(600, 960)),
    ('landscape phone', const Size(800, 360)),
  ];

  Widget harness({
    required Size size,
    double textScale = 1.0,
    required Widget child,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
        padding: const EdgeInsets.only(bottom: 24, top: 24),
        viewPadding: const EdgeInsets.only(bottom: 24),
      ),
      child: MaterialApp(home: child),
    );
  }

  group('CT-01 Role selection across screen sizes', () {
    for (final entry in sizes) {
      final name = entry.$1;
      final size = entry.$2;
      testWidgets('no overflow on $name ${size.width}x${size.height}',
          (tester) async {
        final auth = AuthProvider();
        final router = GoRouter(
          initialLocation: '/role-selection',
          routes: [
            GoRoute(
              path: '/role-selection',
              builder: (_, __) => const RoleSelectionScreen(),
            ),
          ],
        );

        await tester.binding.setSurfaceSize(size);
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size),
            child: ChangeNotifierProvider.value(
              value: auth,
              child: MaterialApp.router(routerConfig: router),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Welcome to SUTMS'), findsOneWidget);
        expect(find.text('Student'), findsOneWidget);
        expect(find.text('Bus Driver'), findsOneWidget);
        expect(find.text('Administrator'), findsOneWidget);
      });
    }
  });

  group('CT-02 Large system font scale', () {
    testWidgets('role selection survives textScale 1.3 on 360x800',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final auth = AuthProvider();
      final router = GoRouter(
        initialLocation: '/role-selection',
        routes: [
          GoRoute(
            path: '/role-selection',
            builder: (_, __) => const RoleSelectionScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ChangeNotifierProvider.value(
            value: auth,
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Welcome to SUTMS'), findsOneWidget);
    });

    testWidgets('duty-like scroll layout survives textScale 1.3', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        harness(
          size: const Size(360, 800),
          textScale: 1.3,
          child: Scaffold(
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'TRIP ACTIVE',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Sharing GPS with students & admin',
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    const Text('Assigned Duties'),
                    const SizedBox(height: 120, child: Center(child: Text('empty'))),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('END TRIP'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: (800 * 0.35).clamp(240.0, 420.0),
                      child: const ColoredBox(color: Color(0xFFE8EEF5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('END TRIP'), findsOneWidget);
      expect(find.textContaining('Sharing GPS'), findsOneWidget);
    });
  });

  group('CT-03 OsmMapView size compatibility', () {
    testWidgets('tiny bounds show placeholder (no TileLayer crash)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 10,
              height: 10,
              child: OsmMapView(followBus: false),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('normal phone map bounds build without layout overflow',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      // Ignore OSM tile HTTP 400s from the test binding's fake HttpClient.
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        final msg = details.exceptionAsString();
        if (msg.contains('ClientException') || msg.contains('status 400')) {
          return;
        }
        oldOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = oldOnError);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 280,
              child: OsmMapView(
                busLocation: LatLng(25.1450, 62.3600),
                followBus: true,
                busLabel: 'UG-01',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final overflow = tester.takeException();
      expect(
        overflow,
        isNull,
        reason: 'map marker/controls must not overflow: $overflow',
      );
      expect(find.byType(OsmMapView), findsOneWidget);
    });

    testWidgets('landscape map card height stays in clamp range', (tester) async {
      final mapH = (360 * 0.35).clamp(240.0, 420.0);
      expect(mapH, greaterThanOrEqualTo(240));
      expect(mapH, lessThanOrEqualTo(420));

      await tester.binding.setSurfaceSize(const Size(800, 360));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const Text('TRIP ACTIVE'),
                  SizedBox(
                    height: mapH,
                    width: double.infinity,
                    child: const ColoredBox(
                      color: Color(0xFFE8EEF5),
                      child: Center(child: Text('MAP_SLOT')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('MAP_SLOT'), findsOneWidget);
    });
  });

  group('CT-04 AsyncStateView on small phones', () {
    testWidgets('error + Retry fit on 320x568', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        harness(
          size: const Size(320, 568),
          child: Scaffold(
            body: AsyncStateView<List<String>>(
              stream: Stream<List<String>>.error(
                StateError('Please log in again to load data.'),
              ),
              isEmpty: (d) => d.isEmpty,
              emptyMessage: 'empty',
              onRetry: () {},
              builder: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Please log in again'), findsOneWidget);
    });
  });

  group('CT-05 Auth routing compatibility across roles', () {
    test('live-tracking paths resolve consistently for each role', () {
      expect(
        AuthRouteGuard.redirect(
          location: '/live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'student',
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.redirect(
          location: '/admin-live-tracking',
          appAuthenticated: true,
          hasFirebaseUser: true,
          role: 'admin',
        ),
        isNull,
      );
      expect(
        AuthRouteGuard.isAdminPath('/admin-live-tracking'),
        isTrue,
      );
      expect(
        AuthRouteGuard.isStudentPath('/live-tracking'),
        isTrue,
      );
    });
  });

  group('CT-06 Package / platform contracts (OSM free stack)', () {
    test('pubspec uses flutter_map + latlong2, not google_maps_flutter', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('flutter_map:'));
      expect(pubspec, contains('latlong2:'));
      expect(pubspec, contains('geolocator:'));
      expect(pubspec.contains('google_maps_flutter'), isFalse);
    });

    test('Android manifest has location + FGS permissions', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, contains('ACCESS_FINE_LOCATION'));
      expect(manifest, contains('FOREGROUND_SERVICE'));
      expect(manifest, contains('FOREGROUND_SERVICE_LOCATION'));
      expect(manifest, contains('GeolocatorLocationService'));
      expect(manifest.contains('com.google.android.geo.API_KEY'), isFalse);
    });

    test('Android minSdk supports modern location APIs', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('minSdk = 24'));
      expect(gradle, contains('targetSdk = 36'));
    });

    test('iOS AppDelegate does not initialize Google Maps SDK', () {
      final swift = File('ios/Runner/AppDelegate.swift').readAsStringSync();
      expect(swift.contains('import GoogleMaps'), isFalse);
      expect(swift.contains('GMSServices'), isFalse);
    });

    test('MapsService works with latlong2 LatLng (cross-platform math)', () {
      final svc = MapsService();
      final eta = svc.getETAString(
        const LatLng(25.1450, 62.3600),
        const LatLng(25.1550, 62.3700),
      );
      expect(eta, isNotEmpty);
      expect(eta.toLowerCase(), anyOf(contains('min'), contains('arriving')));
      final km = svc.calculateDistance(25.1450, 62.3600, 25.1550, 62.3700);
      expect(km, greaterThan(0));
      expect(km.isFinite, isTrue);
    });

    test('OsmMapView fallback center is finite Gwadar coords', () {
      expect(OsmMapView.gwadarFallback.latitude.isFinite, isTrue);
      expect(OsmMapView.gwadarFallback.longitude.isFinite, isTrue);
      expect(OsmMapView.gwadarFallback.latitude, closeTo(25.1450, 0.01));
      expect(OsmMapView.gwadarFallback.longitude, closeTo(62.3600, 0.01));
    });
  });
}
