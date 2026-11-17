import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sutms/config/auth_route_guard.dart';
import 'package:sutms/models/gps_location_model.dart';
import 'package:sutms/models/route_model.dart';
import 'package:sutms/models/trip_model.dart';
import 'package:sutms/providers/auth_provider.dart';
import 'package:sutms/services/trip_tracking_service.dart';
import 'package:sutms/utils/map_marker_helper.dart';
import 'package:sutms/utils/perf_log.dart';

/// Load tests: simulate many concurrent clients / GPS bursts without live Firebase.
/// Validates that SUTMS hot paths remain correct and finish within load budgets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => PerfLog.resetForTest());

  group('LT-01 Concurrent role navigation load', () {
    test('50 simulated users × 200 redirects under 2s, no crashes', () async {
      const users = 50;
      const hitsPerUser = 200;
      final roles = ['admin', 'driver', 'student'];
      final paths = [
        '/live-tracking',
        '/admin-live-tracking',
        '/driver-dashboard',
        '/student-dashboard',
        '/manage-routes',
        '/login',
      ];

      final ms = await PerfLog.measureAsync('lt_nav_50x200', () async {
        await Future.wait(List.generate(users, (u) async {
          final role = roles[u % roles.length];
          for (var i = 0; i < hitsPerUser; i++) {
            AuthRouteGuard.redirect(
              location: paths[(u + i) % paths.length],
              appAuthenticated: true,
              hasFirebaseUser: true,
              role: role,
            );
          }
        }));
      });

      expect(ms, lessThan(2000), reason: 'nav load took ${ms}ms');
    });
  });

  group('LT-02 Concurrent AuthProvider sessions', () {
    test('100 parallel login/logout state cycles under 1s', () async {
      final ms = await PerfLog.measureAsync('lt_auth_100', () async {
        await Future.wait(List.generate(100, (i) async {
          final auth = AuthProvider();
          var ticks = 0;
          auth.addListener(() => ticks++);
          auth.setAuthenticated(
            true,
            role: i.isEven ? 'driver' : 'student',
            uid: 'load_user_$i',
            email: 'u$i@uog.edu.pk',
          );
          auth.cacheProfile(displayName: 'Load $i', role: auth.userRole);
          expect(auth.isAuthenticated, isTrue);
          auth.setAuthenticated(false);
          expect(auth.isAuthenticated, isFalse);
          expect(ticks, greaterThan(0));
        }));
      });
      expect(ms, lessThan(1000), reason: 'auth load took ${ms}ms');
    });
  });

  group('LT-03 GPS burst (many active buses)', () {
    test('200 buses × 25 GPS samples stay valid under 2s', () {
      final rng = Random(42);
      var liveCount = 0;

      final ms = PerfLog.measureSync('lt_gps_200x25', () {
        for (var bus = 0; bus < 200; bus++) {
          final tripId = 'trip_load_$bus';
          for (var tick = 0; tick < 25; tick++) {
            final lat = 25.14 + rng.nextDouble() * 0.05;
            final lng = 62.36 + rng.nextDouble() * 0.05;
            final gps = GpsLocationModel.fromMap({
              'tripId': tripId,
              'busId': 'bus_$bus',
              'driverId': 'driver_auth_$bus',
              'latitude': lat,
              'longitude': lng,
              'speed': rng.nextDouble() * 40,
              'heading': rng.nextDouble() * 360,
              'isActive': true,
              'updatedAt': DateTime.now().toUtc(),
            }, tripId);
            expect(gps.hasValidCoords, isTrue);
            expect(gps.driverId, 'driver_auth_$bus');
            if (gps.isActive && gps.hasValidCoords) liveCount++;
          }
        }
      });

      expect(liveCount, 200 * 25);
      expect(ms, lessThan(2000), reason: 'gps burst took ${ms}ms');
    });
  });

  group('LT-04 Concurrent trip parse + START gate', () {
    test('80 workers × 100 trip ops under 2s', () async {
      final ms = await PerfLog.measureAsync('lt_trip_80x100', () async {
        await Future.wait(List.generate(80, (w) async {
          for (var i = 0; i < 100; i++) {
            final trip = TripModel.fromMap({
              'busId': 'b_${w}_$i',
              'driverId': 'd_$w',
              'routeId': 'r_$w',
              'busNumber': 'UG-$w',
              'routeName': 'Route $w',
              'driverName': 'Driver $w',
              'status': i.isEven ? 'ACTIVE' : 'COMPLETED',
              'lastLat': 25.1 + w * 0.001,
              'lastLng': 62.3 + i * 0.001,
            }, 't_${w}_$i');

            if (i.isEven) {
              expect(trip.isActive, isTrue);
              TripTrackingService.assertCanStartTrip(
                verificationStatus: 'approved',
                busId: trip.busId,
                routeId: trip.routeId,
              );
            } else {
              expect(trip.isActive, isFalse);
              expect(
                () => TripTrackingService.assertCanStartTrip(
                  verificationStatus: 'pending',
                  busId: trip.busId,
                  routeId: trip.routeId,
                ),
                throwsA(isA<TripStartException>()),
              );
            }
          }
        }));
      });
      expect(ms, lessThan(2000), reason: 'trip load took ${ms}ms');
    });
  });

  group('LT-05 Map geometry under many routes', () {
    test('build polylines for 300 routes × 12 stops under 1.5s', () {
      final routes = List.generate(300, (n) {
        return RouteModel.fromMap('route_load_$n', {
          'routeName': 'Load Route $n',
          'stops': [
            for (var s = 0; s < 12; s++)
              {
                'stopName': 'Stop $s',
                'lat': 25.10 + n * 0.001 + s * 0.002,
                'lng': 62.30 + n * 0.001 + s * 0.002,
                'order': s,
              },
          ],
        });
      });

      var pointTotal = 0;
      final ms = PerfLog.measureSync('lt_map_300', () {
        for (final route in routes) {
          final pts = MapMarkerHelper.routePolyline(route);
          final stops = MapMarkerHelper.stopMarkers(route);
          expect(pts.length, 12);
          expect(stops.length, 12);
          pointTotal += pts.length;
        }
      });

      expect(pointTotal, 300 * 12);
      expect(ms, lessThan(1500), reason: 'map load took ${ms}ms');
    });
  });

  group('LT-06 Stream burst (student live updates)', () {
    test('single stream delivers 500 GPS ticks without drop under 2s', () async {
      final controller = StreamController<GpsLocationModel>.broadcast();
      final received = <GpsLocationModel>[];
      final sub = controller.stream.listen(received.add);

      final ms = await PerfLog.measureAsync('lt_stream_500', () async {
        for (var i = 0; i < 500; i++) {
          controller.add(
            GpsLocationModel.fromMap({
              'tripId': 'live_1',
              'busId': 'bus_1',
              'driverId': 'auth_1',
              'latitude': 25.14 + i * 0.00001,
              'longitude': 62.36 + i * 0.00001,
              'isActive': true,
            }, 'live_1'),
          );
        }
        // Allow microtask queue to drain listeners.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 20));
      });

      await sub.cancel();
      await controller.close();

      expect(received.length, 500);
      expect(received.last.hasValidCoords, isTrue);
      expect(ms, lessThan(2000), reason: 'stream burst took ${ms}ms');
    });
  });

  group('LT-07 Mixed concurrent load (FYP peak hour)', () {
    test('admins + drivers + students hot paths together under 3s', () async {
      final ms = await PerfLog.measureAsync('lt_mixed_peak', () async {
        await Future.wait([
          // 30 admins scanning live list models
          Future(() {
            for (var a = 0; a < 30; a++) {
              for (var t = 0; t < 40; t++) {
                TripModel.fromMap({
                  'busId': 'b$t',
                  'driverId': 'd$t',
                  'routeId': 'r$t',
                  'status': 'ACTIVE',
                  'busNumber': 'UG-$t',
                  'routeName': 'R$t',
                  'driverName': 'D$t',
                }, 'admin_view_${a}_$t');
              }
            }
          }),
          // 40 drivers asserting start gate
          Future(() {
            for (var d = 0; d < 40; d++) {
              TripTrackingService.assertCanStartTrip(
                verificationStatus: 'approved',
                busId: 'bus_$d',
                routeId: 'route_$d',
              );
            }
          }),
          // 100 students hitting live-tracking guard
          Future(() {
            for (var s = 0; s < 100; s++) {
              expect(
                AuthRouteGuard.redirect(
                  location: '/live-tracking',
                  appAuthenticated: true,
                  hasFirebaseUser: true,
                  role: 'student',
                ),
                isNull,
              );
            }
          }),
          // Map helpers for 50 routes
          Future(() {
            for (var r = 0; r < 50; r++) {
              final route = RouteModel.fromMap('mix_$r', {
                'routeName': 'Mix $r',
                'stops': [
                  for (var s = 0; s < 6; s++)
                    {
                      'stopName': 'S$s',
                      'lat': 25.1 + s * 0.01,
                      'lng': 62.3 + s * 0.01,
                      'order': s,
                    },
                ],
              });
              MapMarkerHelper.routePolyline(route);
              MapMarkerHelper.stopMarkers(route);
            }
          }),
        ]);
      });

      expect(ms, lessThan(3000), reason: 'mixed peak load took ${ms}ms');
    });
  });
}
