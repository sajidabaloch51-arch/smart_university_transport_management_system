import 'package:flutter/material.dart';
import '../../widgets/role_card.dart';
import 'student_registration_screen.dart';

/// Legacy registration role picker (not used by go_router portal flow).
/// Drivers cannot self-register — only students can create accounts here.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Hero(
                tag: 'auth_icon',
                child: Icon(Icons.directions_bus_rounded,
                    size: 60, color: Color(0xFF1565C0)),
              ),
              const SizedBox(height: 20),
              Text(
                'Create New Account',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Student self-registration only. Driver accounts are created by Admin.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              RoleCard(
                icon: Icons.school,
                title: 'Student',
                description:
                    'Access transport services including bus routes, schedules, notices, and live tracking.',
                onTap: () => Navigator.push(
                  context,
                  _createRoute(const StudentRegistrationScreen()),
                ),
              ),
              const SizedBox(height: 20),
              const RoleCard(
                icon: Icons.drive_eta,
                title: 'Driver',
                description:
                    'Driver accounts are created by the Transport Office. Contact Admin to get access.',
                isDisabled: true,
                onTap: _doNothing,
              ),
              const SizedBox(height: 20),
              const RoleCard(
                icon: Icons.admin_panel_settings,
                title: 'Administrator',
                description:
                    'Administrator accounts are created and managed by the University system only.',
                isDisabled: true,
                onTap: _doNothing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _doNothing() {}

  Route _createRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
}
