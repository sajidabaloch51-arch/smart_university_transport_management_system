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

/// Stress tests: push hot paths past normal load to find breakage / corruption.
/// No live Firebase or device GPS — pure Dart + Flutter test harness.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => PerfLog.resetForTest());

  group('ST-01 Extreme concurrent navigation stress', () {
    test('200 users × 500 redirects stay correct under 5s', () async {
      const users = 200;
      const hits = 500;
      final roles = ['admin', 'driver', 'student', null];
      final paths = [
        '/live-tracking',
        '/admin-live-tracking',
        '/driver-dashboard',
        '/student-dashboard',
        '/manage-buses',
        '/manage-routes',
        '/login',
        '/role-selection',
      ];

      var ok = 0;
      final ms = await PerfLog.measureAsync('st_nav_200x500', () async {
        await Future.wait(List.generate(users, (u) async {
          final role = roles[u % roles.length];
          for (var i = 0; i < hits; i++) {
            final loc = paths[(u + i) % paths.length];
            final redirect = AuthRouteGuard.redirect(
              location: loc,
              appAuthenticated: role != null,
              hasFirebaseUser: role != null,
              role: role,
            );
            // Logged-out users must bounce from protected paths.
            if (role == null && !AuthRouteGuard.publicPaths.contains(loc)) {
              expect(redirect, '/role-selection');
            }
            ok++;
          }
        }));
      });

      expect(ok, users * hits);
      expect(ms, lessThan(5000), reason: 'nav stress took ${ms}ms');
    });
  });

  group('ST-02 Sustained GPS flood', () {
    test('500 buses × 100 ticks remain valid under 8s', () {
      final rng = Random(7);
      var valid = 0;
      var invalid = 0;

      final ms = PerfLog.measureSync('st_gps_500x100', () {
        for (var bus = 0; bus < 500; bus++) {
          final tripId = 'stress_trip_$bus';
          for (var t = 0; t < 100; t++) {
            // Every 17th sample is a bad 0,0 placeholder (must be rejected).
            final bad = t % 17 == 0;
            final gps = GpsLocationModel.fromMap({
              'tripId': tripId,
              'busId': 'bus_$bus',
              'driverId': 'auth_$bus',
              'latitude': bad ? 0 : 25.1 + rng.nextDouble() * 0.2,
              'longitude': bad ? 0 : 62.2 + rng.nextDouble() * 0.2,
              'speed': rng.nextDouble() * 60,
              'heading': rng.nextDouble() * 360,
              'isActive': true,
            }, tripId);
            if (gps.hasValidCoords) {
              valid++;
              expect(gps.driverId, 'auth_$bus');
            } else {
              invalid++;
              expect(gps.isLive, isFalse);
            }
          }
        }
      });

      expect(valid + invalid, 500 * 100);
      expect(invalid, greaterThan(0));
      expect(ms, lessThan(8000), reason: 'gps flood took ${ms}ms');
    });
  });

  group('ST-03 Rapid START TRIP gate thrash', () {
    test('20k alternating allow/deny gates under 3s', () {
      var allowed = 0;
      var denied = 0;
      final ms = PerfLog.measureSync('st_gate_20k', () {
        for (var i = 0; i < 20000; i++) {
          if (i.isEven) {
            TripTrackingService.assertCanStartTrip(
              verificationStatus: 'approved',
              busId: 'bus_$i',
              routeId: 'route_$i',
            );
            allowed++;
          } else {
            expect(
              () => TripTrackingService.assertCanStartTrip(
                verificationStatus: i % 4 == 1 ? 'pending' : 'approved',
                busId: i % 4 == 3 ? 'Not Assigned' : 'bus_$i',
                routeId: i % 4 == 3 ? 'route_$i' : '',
              ),
              throwsA(isA<TripStartException>()),
            );
            denied++;
          }
        }
      });
      expect(allowed, 10000);
      expect(denied, 10000);
      expect(ms, lessThan(3000), reason: 'gate thrash took ${ms}ms');
    });
  });

  group('ST-04 AuthProvider session thrash', () {
    test('2k create/login/logout cycles under 2s', () {
      var cycles = 0;
      final ms = PerfLog.measureSync('st_auth_2k', () {
        for (var i = 0; i < 2000; i++) {
          final auth = AuthProvider();
          auth.setAuthenticated(
            true,
            role: i % 3 == 0 ? 'admin' : (i % 3 == 1 ? 'driver' : 'student'),
            uid: 'stress_$i',
            email: 's$i@uog.edu.pk',
          );
          expect(auth.isAuthenticated, isTrue);
          auth.cacheProfile(displayName: 'S$i', role: auth.userRole);
          auth.setAuthenticated(false);
          expect(auth.isAuthenticated, isFalse);
          cycles++;
        }
      });
      expect(cycles, 2000);
      expect(ms, lessThan(2000), reason: 'auth thrash took ${ms}ms');
    });
  });

  group('ST-05 Huge route map geometry', () {
    test('80 routes × 40 stops polyline/markers under 3s', () {
      var points = 0;
      final ms = PerfLog.measureSync('st_map_80x40', () {
        for (var r = 0; r < 80; r++) {
          final route = RouteModel.fromMap('stress_route_$r', {
            'routeName': 'Stress $r',
            'stops': [
              for (var s = 0; s < 40; s++)
                {
                  'stopName': 'Stop $s',
                  'lat': 25.0 + r * 0.01 + s * 0.001,
                  'lng': 62.0 + r * 0.01 + s * 0.001,
                  'order': s,
                },
            ],
          });
          final pts = MapMarkerHelper.routePolyline(route);
          final stops = MapMarkerHelper.stopMarkers(route);
          expect(pts.length, 40);
          expect(stops.length, 40);
          expect(stops.first.isTerminal, isTrue);
          expect(stops.last.isTerminal, isTrue);
          points += pts.length;
        }
      });
      expect(points, 80 * 40);
      expect(ms, lessThan(3000), reason: 'map stress took ${ms}ms');
    });
  });

  group('ST-06 Multi-subscriber GPS stream storm', () {
    test('10 listeners × 1000 ticks, all receive full stream under 4s',
        () async {
      final controller = StreamController<GpsLocationModel>.broadcast();
      final counts = List.filled(10, 0);
      final subs = <StreamSubscription<GpsLocationModel>>[];
      for (var i = 0; i < 10; i++) {
        final idx = i;
        subs.add(controller.stream.listen((_) => counts[idx]++));
      }

      final ms = await PerfLog.measureAsync('st_stream_10x1000', () async {
        for (var t = 0; t < 1000; t++) {
          controller.add(
            GpsLocationModel.fromMap({
              'tripId': 'storm',
              'busId': 'bus_storm',
              'driverId': 'auth_storm',
              'latitude': 25.14 + t * 0.00001,
              'longitude': 62.36 + t * 0.00001,
              'isActive': true,
            }, 'storm'),
          );
        }
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      for (final s in subs) {
        await s.cancel();
      }
      await controller.close();

      for (final c in counts) {
        expect(c, 1000);
      }
      expect(ms, lessThan(4000), reason: 'stream storm took ${ms}ms');
    });
  });

  group('ST-07 Trip model memory churn', () {
    test('50k ACTIVE→COMPLETED trip parses under 5s', () {
      var active = 0;
      var done = 0;
      final ms = PerfLog.measureSync('st_trip_50k', () {
        for (var i = 0; i < 50000; i++) {
          final trip = TripModel.fromMap({
            'busId': 'b${i % 200}',
            'driverId': 'd${i % 200}',
            'routeId': 'r${i % 50}',
            'busNumber': 'UG-${i % 200}',
            'routeName': 'R${i % 50}',
            'driverName': 'D${i % 200}',
            'status': i.isEven ? 'ACTIVE' : 'COMPLETED',
            'lastLat': 25.1 + (i % 100) * 0.001,
            'lastLng': 62.3 + (i % 100) * 0.001,
          }, 'trip_$i');
          if (trip.isActive) {
            active++;
          } else {
            done++;
          }
          // Ensure toMap stays lean under churn.
          expect(trip.toMap().containsKey('password'), isFalse);
        }
      });
      expect(active, 25000);
      expect(done, 25000);
      expect(ms, lessThan(5000), reason: 'trip churn took ${ms}ms');
    });
  });

  group('ST-08 Peak-hour overload mix', () {
    test('stacked extreme workloads complete under 6s without failure',
        () async {
      final ms = await PerfLog.measureAsync('st_peak_mix', () async {
        await Future.wait([
          Future(() {
            for (var i = 0; i < 5000; i++) {
              AuthRouteGuard.redirect(
                location: i.isEven ? '/live-tracking' : '/admin-live-tracking',
                appAuthenticated: true,
                hasFirebaseUser: true,
                role: i % 3 == 0
                    ? 'admin'
                    : (i % 3 == 1 ? 'driver' : 'student'),
              );
            }
          }),
          Future(() {
            for (var i = 0; i < 3000; i++) {
              TripTrackingService.assertCanStartTrip(
                verificationStatus: 'approved',
                busId: 'bus_$i',
                routeId: 'route_$i',
              );
            }
          }),
          Future(() {
            for (var i = 0; i < 2000; i++) {
              final gps = GpsLocationModel.fromMap({
                'tripId': 'mix_$i',
                'busId': 'b_$i',
                'driverId': 'auth_$i',
                'latitude': 25.14,
                'longitude': 62.36,
                'isActive': true,
              }, 'mix_$i');
              expect(gps.hasValidCoords, isTrue);
            }
          }),
          Future(() {
            for (var i = 0; i < 100; i++) {
              final route = RouteModel.fromMap('mix_r_$i', {
                'routeName': 'Mix $i',
                'stops': [
                  for (var s = 0; s < 20; s++)
                    {
                      'stopName': 'S$s',
                      'lat': 25.1 + s * 0.01,
                      'lng': 62.3 + s * 0.01,
                      'order': s,
                    },
                ],
              });
              expect(MapMarkerHelper.routePolyline(route).length, 20);
            }
          }),
        ]);
      });
      expect(ms, lessThan(6000), reason: 'peak mix took ${ms}ms');
    });
  });
}
