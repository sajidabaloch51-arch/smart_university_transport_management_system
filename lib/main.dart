import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/app_router.dart';
import 'theme/app_theme.dart';
import 'constants/strings.dart';
import 'providers/auth_provider.dart';
import 'providers/driver_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/student_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/route_provider.dart';
import 'providers/schedule_provider.dart';
import 'providers/notice_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase in a non-blocking way for the initial UI render
  _initializeFirebase();

  runApp(const SUTMSApp());
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      // Use a timeout to ensure we don't hang indefinitely
      await Firebase.initializeApp().timeout(const Duration(seconds: 5));
    }
  } catch (e) {
    debugPrint("Firebase initialization error or timeout: $e");
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
      ],
      child: MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          ErrorWidget.builder = (details) {
            return Scaffold(
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 16),
                      const Text("An unexpected error occurred", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(details.exception.toString(), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          };
          return child!;
        },
      ),
    );
  }
}
