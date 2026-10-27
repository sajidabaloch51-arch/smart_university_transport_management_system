import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/driver_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/duty_model.dart';
import '../../models/alert_model.dart';
import '../../services/duty_service.dart';
import '../../services/alert_service.dart';
import '../../services/auth_service.dart';
import '../../services/password_hasher.dart';
import '../../core/validators/app_validators.dart';
import '../../utils/karachi_time.dart';
import '../../widgets/driver_card.dart';
import '../../widgets/duty_card.dart';
import '../../widgets/alert_card.dart';
import 'driver_route_screen.dart';
import 'duty_screen.dart';
import 'driver_notice_screen.dart';
import 'driver_profile_screen.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;
  int _refreshToken = 0;
  bool _changePasswordPromptShown = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardSummary(
        key: ValueKey('dash-$_refreshToken'),
        onNavigateToRoute: () => _onTabChanged(1),
        onNavigateToNotices: () => _onTabChanged(3),
        onRetry: _refresh,
      ),
      const DriverRouteScreen(),
      DutyScreen(key: ValueKey('duty-$_refreshToken'), refreshToken: _refreshToken),
      DriverNoticeScreen(
        key: ValueKey('notices-$_refreshToken'),
        refreshToken: _refreshToken,
      ),
      const DriverProfileScreen(),
    ];
    // Start driver fetch immediately (don't wait for first frame).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final driverProvider = Provider.of<DriverProvider>(context, listen: false);
      final uid = authProvider.uid;
      if (uid != null) {
        // Fire-and-forget — UI uses cache / streams while this completes.
        // ignore: discarded_futures
        driverProvider.init(uid).then((_) {
          if (mounted) _maybePromptChangePassword();
        });
      }
    });
  }

  void _maybePromptChangePassword() {
    if (_changePasswordPromptShown || !mounted) return;
    final driver =
        Provider.of<DriverProvider>(context, listen: false).driver;
    if (driver == null || !driver.mustChangePassword) return;
    _changePasswordPromptShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _ChangePasswordDialog(),
    );
  }

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _refresh() {
    final driverProvider = Provider.of<DriverProvider>(context, listen: false);
    if (driverProvider.driver != null) {
      driverProvider.init(driverProvider.driver!.uid);
    }
    setState(() {
      _refreshToken++;
      _pages[0] = DashboardSummary(
        key: ValueKey('dash-$_refreshToken'),
        onNavigateToRoute: () => _onTabChanged(1),
        onNavigateToNotices: () => _onTabChanged(3),
        onRetry: _refresh,
      );
      _pages[2] = DutyScreen(
        key: ValueKey('duty-$_refreshToken'),
        refreshToken: _refreshToken,
      );
      _pages[3] = DriverNoticeScreen(
        key: ValueKey('notices-$_refreshToken'),
        refreshToken: _refreshToken,
      );
    });
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Driver Dashboard';
      case 1:
        return 'My Route';
      case 2:
        return 'Duty Tracking';
      case 3:
        return 'Official Notices';
      case 4:
        return 'My Profile';
      default:
        return 'Driver Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          _onTabChanged(0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Use Logout button to exit session'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_selectedIndex != 0) {
                setState(() => _selectedIndex = 0);
              } else {
                context.go('/role-selection');
              }
            },
          ),
          title: Text(_getAppBarTitle()),
          actions: _selectedIndex == 0
              ? [
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refresh,
                  ),
                ]
              : null,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onTabChanged,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.route_outlined),
              selectedIcon: Icon(Icons.route),
              label: 'Route',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_history_outlined),
              selectedIcon: Icon(Icons.work_history),
              label: 'Duty',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Notices',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

/// Home tab — streams created once when uid is ready (not inside build()).
class DashboardSummary extends StatefulWidget {
  final VoidCallback onNavigateToRoute;
  final VoidCallback onNavigateToNotices;
  final VoidCallback onRetry;

  const DashboardSummary({
    super.key,
    required this.onNavigateToRoute,
    required this.onNavigateToNotices,
    required this.onRetry,
  });

  @override
  State<DashboardSummary> createState() => _DashboardSummaryState();
}

class _DashboardSummaryState extends State<DashboardSummary> {
  final _dutyService = DutyService();
  final _alertService = AlertService();

  Stream<List<DutyModel>>? _dutiesStream;
  Stream<List<AlertModel>>? _alertsStream;
  String? _boundDriverId;
  String? _boundDutyDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindIfReady());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindIfReady();
  }

  /// All identity keys that may appear on duty/alert docs (Auth ≠ seed doc id).
  List<String> _resolveDriverIds() {
    final ids = <String>{};
    final fromDriver = context.read<DriverProvider>().driver?.uid;
    if (fromDriver != null && fromDriver.isNotEmpty) ids.add(fromDriver);
    final fromAppAuth = context.read<AuthProvider>().uid;
    if (fromAppAuth != null && fromAppAuth.isNotEmpty) ids.add(fromAppAuth);
    try {
      final authUid = FirebaseAuth.instance.currentUser?.uid;
      if (authUid != null && authUid.isNotEmpty) ids.add(authUid);
    } catch (_) {}
    // Seeded demo driver doc id — Admin assign often uses this.
    ids.add('driver_id');
    return ids.toList();
  }

  void _bindIfReady() {
    final ids = _resolveDriverIds();
    if (ids.isEmpty) {
      debugPrint('DashboardSummary waiting for driver uid…');
      return;
    }
    final primary = ids.first;

    final today = KarachiTime.dateString();
    final boundKey = ids.join('|');
    if (_dutiesStream != null &&
        _boundDriverId == boundKey &&
        _boundDutyDate == today) {
      return;
    }

    String? authUid;
    String? projectId;
    try {
      authUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    try {
      if (Firebase.apps.isNotEmpty) {
        projectId = Firebase.app().options.projectId;
      }
    } catch (_) {}

    debugPrint(
      'DashboardSummary bind ids=$ids today=$today '
      'authUid=$authUid projectId=$projectId',
    );

    _boundDriverId = boundKey;
    _boundDutyDate = today;
    // Live .snapshots() — never wrap in Stream.timeout.
    _dutiesStream = _dutyService.streamTodayDuties(
      driverId: primary,
      dutyDate: today,
      alternateDriverIds: ids.skip(1).toList(),
    );
    _alertsStream = _alertService.streamDriverAlerts(
      primary,
      limit: 5,
      alternateDriverIds: ids.skip(1).toList(),
    );
    if (mounted) setState(() {});
  }

  void _logSnapError(String label, Object? error) {
    if (error is FirebaseException) {
      debugPrint(
        '🔥 DashboardSummary.$label snapshot.error '
        'code=${error.code} message=${error.message}',
      );
    } else if (error != null) {
      debugPrint('🔥 DashboardSummary.$label snapshot.error: $error');
    }
  }

  String _friendlyError(Object? error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'failed-precondition':
          return 'Database index missing. Ask admin to deploy Firestore indexes.';
        case 'permission-denied':
          return 'Permission denied reading duties/alerts. Deploy updated Firestore rules.';
        case 'unavailable':
          return 'Network unavailable. Check your internet connection.';
        default:
          return 'Could not load (${error.code}).';
      }
    }
    return 'Could not load. Check your internet and retry.';
  }

  void _showHelpDesk(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transport Help Desk'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Need assistance? Contact our support team:'),
            SizedBox(height: 15),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.blue),
              title: Text('Emergency Contact'),
              subtitle: Text('+92 300 999 8888'),
            ),
            ListTile(
              leading: Icon(Icons.email, color: Colors.blue),
              title: Text('Transport Office'),
              subtitle: Text('transport@uog.edu.pk'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DriverProvider, AuthProvider>(
      builder: (context, provider, auth, child) {
        // Re-bind when uid becomes available (never start with null uid).
        if (_dutiesStream == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _bindIfReady();
          });
        }

        final authUid = auth.uid;
        if (provider.driver == null &&
            (authUid == null || authUid.isEmpty)) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Waiting for sign-in…'),
              ],
            ),
          );
        }

        if (provider.driver == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading dashboard…'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => widget.onRetry(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                Text(
                  provider.driver!.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                StreamBuilder<List<DutyModel>>(
                  stream: _dutiesStream,
                  builder: (context, dutySnap) {
                    if (dutySnap.hasError) {
                      _logSnapError('duties', dutySnap.error);
                    }
                    final duties = dutySnap.data ?? [];
                    final current = duties.isEmpty ? null : duties.first;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DriverCard(
                          driver: provider.driver!,
                          busNoOverride: current?.busNo,
                          routeOverride: current?.route,
                        ),
                        const SizedBox(height: 30),
                        _sectionTitle("Today's Active Duties"),
                        if (_dutiesStream == null ||
                            (dutySnap.connectionState ==
                                    ConnectionState.waiting &&
                                !dutySnap.hasData &&
                                !dutySnap.hasError))
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (dutySnap.hasError)
                          _errorBox(
                            _friendlyError(dutySnap.error),
                            onRetry: widget.onRetry,
                          )
                        else if (duties.isEmpty)
                          _emptyBox('No schedules assigned for today.')
                        else
                          ...duties.map((d) => DutyCard(duty: d)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
                _sectionTitle('Recent Alerts'),
                StreamBuilder<List<AlertModel>>(
                  stream: _alertsStream,
                  builder: (context, alertSnap) {
                    if (alertSnap.hasError) {
                      _logSnapError('alerts', alertSnap.error);
                    }
                    if (_alertsStream == null ||
                        (alertSnap.connectionState ==
                                ConnectionState.waiting &&
                            !alertSnap.hasData &&
                            !alertSnap.hasError)) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (alertSnap.hasError) {
                      return _errorBox(
                        _friendlyError(alertSnap.error),
                        onRetry: widget.onRetry,
                      );
                    }
                    final alerts = alertSnap.data ?? [];
                    if (alerts.isEmpty) {
                      return _emptyBox('No active transport alerts.');
                    }
                    return Column(
                      children: alerts
                          .map(
                            (a) => AlertCard(
                              alert: a,
                              onTap: widget.onNavigateToNotices,
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 30),
                _sectionTitle('Quick Actions'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.8,
                  children: [
                    _ActionBtn(
                      icon: Icons.map,
                      label: 'Open Map',
                      color: Colors.green,
                      onTap: widget.onNavigateToRoute,
                    ),
                    _ActionBtn(
                      icon: Icons.support_agent,
                      label: 'Help Desk',
                      color: Colors.orange,
                      onTap: () => _showHelpDesk(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1565C0),
        ),
      ),
    );
  }

  Widget _emptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _errorBox(String message, {required VoidCallback onRetry}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade800, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shadowColor: color.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.85), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Forced after Admin creates a driver with a temporary password.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final newPassword = _passwordController.text;
    final driverProvider =
        Provider.of<DriverProvider>(context, listen: false);
    final driver = driverProvider.driver;

    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        await AuthService().updatePassword(newPassword);
      } else if (driver != null && Firebase.apps.isNotEmpty) {
        // Demo / Auth-fallback accounts store a hash on the user doc.
        final hash = PasswordHasher.hash(newPassword);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(driver.uid)
            .set({'passwordHash': hash}, SetOptions(merge: true));
      } else {
        throw AuthServiceException(
          'Cannot change password right now. Check your connection.',
        );
      }

      if (driver != null) {
        await driverProvider.updateDriver(
          driver.copyWith(mustChangePassword: false),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is AuthServiceException ? e.message : '$e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your account was created with a temporary password. '
              'Please set a new password to continue.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(),
              ),
              validator: AppValidators.validatePassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(),
              ),
              validator: (v) => AppValidators.validateConfirmPassword(
                v,
                _passwordController.text,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save password'),
        ),
      ],
    );
  }
}
