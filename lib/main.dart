import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'theme/app_theme.dart';
import 'constants/strings.dart';
import 'firebase_options.dart';
import 'services/firebase_bootstrap.dart';
import 'services/firestore_seed_service.dart';
import 'services/firestore_web_fix.dart';

import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/student_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/route_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/notice_provider.dart';
import 'providers/live_tracking_provider.dart';
import 'widgets/offline_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  await _initializeFirebase();
  _enableFirestoreCache();
  debugPrint(
    '🔥 Firebase ready project=${DefaultFirebaseOptions.android.projectId} '
    'apps=${Firebase.apps.length}',
  );
  runApp(const SUTMSApp());

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

void _enableFirestoreCache() {
  try {
    if (Firebase.apps.isEmpty) return;
    if (kIsWeb) {
      configureWebFirestore();
    } else {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 40 * 1024 * 1024,
      );
    }
  } catch (e) {
    debugPrint('Firestore cache settings skipped: $e');
  }
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') return;
    debugPrint('Firebase initialization failed: ${e.code} ${e.message}');
  } catch (e) {
    final message = e.toString();
    if (message.contains('duplicate-app')) return;
    debugPrint('Firebase initialization failed: $e');
  }
}

class SUTMSApp extends StatefulWidget {
  const SUTMSApp({super.key});

  @override
  State<SUTMSApp> createState() => _SUTMSAppState();
}

class _SUTMSAppState extends State<SUTMSApp> {
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _router = AppRouter.create(_auth);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
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
        routerConfig: _router,
        builder: (context, child) {
          return Column(
            children: [
              const OfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          );
        },
      ),
    );
  }
}
