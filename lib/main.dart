import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'theme/app_theme.dart';
import 'constants/strings.dart';
import 'firebase_options.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_seed_service.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/student_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/route_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/notice_provider.dart';
import 'providers/live_tracking_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lightweight error UI — never inject a full Scaffold into the render tree
  // (that caused parent/child assertion crashes on device).
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ),
      ),
    );
  };

  // Only wait for Firebase init — then show UI immediately.
  await _initializeFirebase();
  runApp(const SUTMSApp());

  // Probes + seed run in the background (do not block first frame).
  // ignore: unawaited_futures
  _probeAndSeedBackend();
}

Future<void> _probeAndSeedBackend() async {
  try {
    final firestoreIssue = await FirebaseBootstrap.probeFirestore();
    if (firestoreIssue != null) {
      debugPrint('⚠️ Firestore: $firestoreIssue');
      return;
    }
    debugPrint('✅ Firestore connected (sutms-uog)');
    await FirestoreSeedService.ensureSeedData();

    final rtdbIssue = await FirebaseBootstrap.probeRealtimeDatabase();
    if (rtdbIssue != null) {
      debugPrint('⚠️ Realtime Database: $rtdbIssue');
    } else {
      debugPrint('✅ Realtime Database connected');
    }
  } catch (e) {
    debugPrint('Background Firebase setup skipped: $e');
  }
}

/// Safe Firebase bootstrap: Android may already create [DEFAULT] via google-services.
Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      // Native / prior init already registered the default app.
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Race or native auto-init: treat as success.
    if (e.code == 'duplicate-app') return;
    debugPrint('Firebase initialization failed: ${e.code} ${e.message}');
  } catch (e) {
    final message = e.toString();
    if (message.contains('duplicate-app')) return;
    debugPrint('Firebase initialization failed: $e');
  }
}

class SUTMSApp extends StatelessWidget {
  const SUTMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => NoticeProvider()),
        ChangeNotifierProvider(create: (_) => LiveTrackingProvider()),
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
