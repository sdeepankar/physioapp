import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../services/appwrite_service.dart';

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  bool? _signedIn;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final signedIn = await AppwriteService.instance.isSignedIn();
      if (mounted) setState(() => _signedIn = signedIn);
    } on Object {
      if (mounted) setState(() => _signedIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _signedIn!
        ? AdminDashboard(onSignOut: () => setState(() => _signedIn = false))
        : AdminLoginScreen(onSignedIn: () => setState(() => _signedIn = true));
  }
}

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({required this.onSignedIn, super.key});

  final VoidCallback onSignedIn;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _userId;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_email.text.trim().isEmpty) {
      setState(() => _error = 'Enter your admin account email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final userId = await AppwriteService.instance
          .sendLoginEmailVerificationCode(email: _email.text);
      if (mounted) setState(() => _userId = userId);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final userId = _userId;
    if (userId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppwriteService.instance.verifyEmailCode(
        userId: userId,
        code: _code.text,
      );
      if (mounted) widget.onSignedIn();
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 48,
                      color: appTeal,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Deep Care Admin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: appInk,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in with an account that has the admin role.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: appMuted),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      enabled: !_busy && _userId == null,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Admin email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_userId != null) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _code,
                        enabled: !_busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Email code',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : (_userId == null ? _sendCode : _verifyCode),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _userId == null
                                  ? 'Send sign-in code'
                                  : 'Verify and sign in',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({required this.onSignOut, super.key});

  final VoidCallback onSignOut;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _showNotificationsPage = false;
  bool _showAdminsPage = false;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _adminUsers = [];
  bool _adminsLoading = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String _adminName = 'Admin';
  String? _adminEmail;
  bool _nameSetupPromptShown = false;

  @override
  void initState() {
    super.initState();
    _loadAdminName();
    _load();
  }

  Future<void> _loadAdminName() async {
    String? name;
    String? email;
    try {
      name = await AppwriteService.instance.getAdminDisplayName();
    } on Object {
      // Fall back to the Appwrite account name if no profile name is stored.
    }
    try {
      final user = await AppwriteService.instance.getCurrentUser();
      email = user.email.trim();
      if (name == null || name.isEmpty) name = user.name.trim();
    } on Object {
      // Keep the friendly Admin fallback if the account name is unavailable.
    }
    final displayName = name;
    if (mounted) {
      setState(() {
        _adminEmail = email;
        if (displayName != null && displayName.isNotEmpty) {
          _adminName = displayName;
        }
      });
    }
    if (mounted &&
        (displayName == null || displayName.isEmpty) &&
        !_nameSetupPromptShown) {
      _nameSetupPromptShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editAdminName();
      });
    }
  }

  Future<void> _editAdminName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _AdminNameDialog(
        initialName: _adminName == 'Admin' ? '' : _adminName,
        initials: _adminInitials,
        email: _adminEmail,
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    try {
      final savedName = await AppwriteService.instance.updateAdminDisplayName(
        name,
      );
      if (mounted) setState(() => _adminName = savedName);
    } on Object catch (error) {
      if (mounted) _showMessage(_message(error));
    }
  }

  String get _adminInitials {
    final parts = _adminName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Future.wait([
        AppwriteService.instance.listAdminProviders(),
        AppwriteService.instance.listAdminOrders(),
        AppwriteService.instance.listAdminServices(),
      ]);
      if (!mounted) return;
      setState(() {
        _providers = result[0];
        _orders = result[1];
        _services = result[2];
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAdminUsers() async {
    setState(() => _adminsLoading = true);
    try {
      final rows = await AppwriteService.instance.listAdminUsers();
      if (mounted) setState(() => _adminUsers = rows);
    } on Object catch (error) {
      if (mounted) _showMessage(_message(error));
    } finally {
      if (mounted) setState(() => _adminsLoading = false);
    }
  }

  Future<void> _addAdminUser() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _GrantAdminDialog(),
    );
    if (email == null || email.trim().isEmpty) return;
    await _runAction(() async {
      await AppwriteService.instance.grantAdminAccess(email);
    });
    if (mounted) await _loadAdminUsers();
  }

  Future<void> _verifyProvider(
    Map<String, dynamic> provider,
    String status,
  ) async {
    final userId = provider['userId'] as String? ?? '';
    if (userId.isEmpty) return;
    await _runAction(
      () => AppwriteService.instance.updateProviderVerification(userId, status),
    );
  }

  Future<void> _assignOrder(Map<String, dynamic> order) async {
    final candidates = _eligibleProviders(order);
    if (candidates.isEmpty) {
      final approvedProviders = _providers.where(
        (provider) => provider['verificationStatus'] == 'verified',
      );
      _showMessage(
        approvedProviders.isEmpty
            ? 'No approved providers are available yet. Approve a provider first.'
            : 'All approved providers already have a booking at this time.',
      );
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          _AssignProviderDialog(providers: candidates, services: _services),
    );
    if (selected == null) return;
    final orderId = order[r'$id'] as String? ?? '';
    await _runAction(
      () => AppwriteService.instance.assignOrderToProvider(
        orderId,
        selected['userId'] as String,
      ),
    );
  }

  List<Map<String, dynamic>> _eligibleProviders(Map<String, dynamic> order) {
    // Manual admin assignment is an override. Keep service/area matching for
    // automatic assignment, but show every approved provider in this picker.
    return _providers
        .where(
          (provider) =>
              provider['verificationStatus'] == 'verified' &&
              !_hasScheduleConflict(provider, order),
        )
        .toList();
  }

  bool _hasScheduleConflict(
    Map<String, dynamic> provider,
    Map<String, dynamic> order,
  ) {
    final requestedTime = DateTime.tryParse(
      order['scheduledAt']?.toString() ?? '',
    );
    if (requestedTime == null) return false;
    final providerId = provider['userId'];
    final orderId = order[r'$id'];
    return _orders.any((booking) {
      if (booking[r'$id'] == orderId ||
          booking['assignedProviderId'] != providerId ||
          !const {
            'assigned',
            'accepted',
            'out_for_service',
            'in_progress',
          }.contains(booking['status'])) {
        return false;
      }
      final bookedTime = DateTime.tryParse(
        booking['scheduledAt']?.toString() ?? '',
      );
      return bookedTime != null &&
          bookedTime.millisecondsSinceEpoch ~/ Duration.millisecondsPerMinute ==
              requestedTime.millisecondsSinceEpoch ~/
                  Duration.millisecondsPerMinute;
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
      if (mounted) _showMessage('Changes saved.');
    } on Object catch (error) {
      if (mounted) _showMessage(_message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    await AppwriteService.instance.signOut();
    if (mounted) widget.onSignOut();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _serviceName(dynamic serviceId) {
    for (final service in _services) {
      if (service[r'$id'] == serviceId) {
        return service['name'] as String? ?? 'Care service';
      }
    }
    return 'Care service';
  }

  int get _newBookingRequestCount =>
      _orders.where((row) => row['status'] == 'pending_assignment').length;
  int get _newProviderRequestCount =>
      _providers.where((row) => row['verificationStatus'] == 'pending').length;
  int get _notificationCount =>
      _newBookingRequestCount + _newProviderRequestCount;

  bool get _isDashboardHome =>
      !_showNotificationsPage && !_showAdminsPage && _selectedIndex == 0;

  void _returnToDashboard() {
    setState(() {
      _showNotificationsPage = false;
      _showAdminsPage = false;
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) => PopScope<void>(
    canPop: _isDashboardHome,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _returnToDashboard();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: !_isDashboardHome
            ? IconButton(
                tooltip: 'Back to dashboard',
                onPressed: _returnToDashboard,
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
        title: Text(
          _showNotificationsPage
              ? 'Notifications'
              : _showAdminsPage
              ? 'Admin users'
              : 'Hi, $_adminName',
        ),
        actions: [
          IconButton(
            tooltip: 'Admin profile',
            onPressed: _editAdminName,
            icon: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFDDF4EE),
              child: Text(
                _adminInitials,
                style: const TextStyle(
                  color: appTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (!_showNotificationsPage)
            IconButton(
              tooltip: 'Booking and provider notifications',
              onPressed: () => setState(() => _showNotificationsPage = true),
              icon: Badge(
                isLabelVisible: _notificationCount > 0,
                label: Text('$_notificationCount'),
                child: const Icon(Icons.notifications_none_rounded),
              ),
            ),
          if (!_showNotificationsPage && !_showAdminsPage)
            IconButton(
              tooltip: 'Manage admin users',
              onPressed: () {
                setState(() => _showAdminsPage = true);
                _loadAdminUsers();
              },
              icon: const Icon(Icons.manage_accounts_outlined),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorPanel(message: _error!, onRetry: _load)
          : Stack(
              children: [
                _showNotificationsPage
                    ? _notificationsPage()
                    : _showAdminsPage
                    ? _adminUsersPage()
                    : IndexedStack(
                        index: _selectedIndex,
                        children: [
                          _dashboardPage(),
                          _sectionPage(
                            title: 'Bookings',
                            subtitle:
                                'Track requests and assigned care visits.',
                            child: _orderList(),
                          ),
                          _sectionPage(
                            title: 'Available providers',
                            subtitle:
                                'Approved providers ready to receive bookings.',
                            child: _providerList(
                              providers: _providers
                                  .where(
                                    (row) =>
                                        row['verificationStatus'] ==
                                            'verified' &&
                                        row['isAvailable'] == true,
                                  )
                                  .toList(),
                              emptyMessage: 'No approved providers are currently available.',
                            ),
                          ),
                          _sectionPage(
                            title: 'Provider applications',
                            subtitle: 'Review and approve new care providers.',
                            child: _providerList(
                              providers: _providers
                                  .where(
                                    (row) =>
                                        row['verificationStatus'] == 'pending',
                                  )
                                  .toList(),
                              emptyMessage:
                                  'No provider applications need review.',
                            ),
                          ),
                        ],
                      ),
                if (_busy) const LinearProgressIndicator(),
              ],
            ),
      bottomNavigationBar: _showNotificationsPage || _showAdminsPage
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFDDF4EE),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: 'Bookings',
                ),
                NavigationDestination(
                  icon: Icon(Icons.verified_user_outlined),
                  selectedIcon: Icon(Icons.verified_user_rounded),
                  label: 'Available',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_add_alt_1_outlined),
                  selectedIcon: Icon(Icons.person_add_alt_1_rounded),
                  label: 'Applications',
                ),
              ],
            ),
    ),
  );

  Widget _dashboardPage() {
    final pendingOrders = _orders
        .where((row) => row['status'] == 'pending_assignment')
        .toList();
    final activeOrders = _orders
        .where(
          (row) =>
              ['assigned', 'accepted', 'in_progress'].contains(row['status']),
        )
        .length;
    final completedOrders = _orders
        .where((row) => row['status'] == 'completed')
        .length;
    final availableProviders = _providers
        .where(
          (row) =>
              row['verificationStatus'] == 'verified' &&
              row['isAvailable'] == true,
        )
        .length;
    final pendingProviders = _providers
        .where((row) => row['verificationStatus'] == 'pending')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [appTeal, Color(0xFF08766D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good to see you, $_adminName',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _notificationCount == 0
                          ? 'Everything is up to date.'
                          : '$_notificationCount items need your attention today.',
                      style: const TextStyle(color: Color(0xFFD9F2EC)),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _showNotificationsPage = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0x99FFFFFF)),
                      ),
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        size: 18,
                      ),
                      label: const Text('Review notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.space_dashboard_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _dashboardHeading('At a glance', 'Your service activity'),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            crossAxisCount: constraints.maxWidth >= 720
                ? 4
                : constraints.maxWidth >= 480
                ? 3
                : 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: constraints.maxWidth < 350 ? 1.25 : 1.48,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _DashboardMetric(
                label: 'All bookings',
                value: '${_orders.length}',
                icon: Icons.calendar_month_rounded,
              ),
              _DashboardMetric(
                label: 'To assign',
                value: '${pendingOrders.length}',
                icon: Icons.assignment_late_outlined,
                accent: true,
              ),
              _DashboardMetric(
                label: 'Active visits',
                value: '$activeOrders',
                icon: Icons.health_and_safety_outlined,
              ),
              _DashboardMetric(
                label: 'Completed',
                value: '$completedOrders',
                icon: Icons.task_alt_rounded,
              ),
              _DashboardMetric(
                label: 'Available team',
                value: '$availableProviders',
                icon: Icons.verified_user_outlined,
              ),
              _DashboardMetric(
                label: 'Applications',
                value: '${pendingProviders.length}',
                icon: Icons.person_add_alt_1_rounded,
                accent: true,
              ),
              _DashboardMetric(
                label: 'Care services',
                value: '${_services.length}',
                icon: Icons.medical_services_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _dashboardSection(
          title: 'New booking requests',
          count: pendingOrders.length,
          actionLabel: 'View all',
          onAction: () => setState(() => _selectedIndex = 1),
          children: pendingOrders.isEmpty
              ? [_dashboardEmpty('No bookings are waiting for assignment.')]
              : pendingOrders.take(3).map((order) {
                  final clientName = (order['clientName'] as String? ?? '')
                      .trim();
                  return _dashboardPreview(
                    icon: Icons.event_note_rounded,
                    title: clientName.isEmpty ? 'New booking' : clientName,
                    subtitle:
                        "${order['serviceName'] ?? 'Care service'}  ?  ${order['bookingId'] ?? 'Booking'}",
                    onTap: () => setState(() => _selectedIndex = 1),
                  );
                }).toList(),
        ),
        const SizedBox(height: 14),
        _dashboardSection(
          title: 'Provider applications',
          count: pendingProviders.length,
          actionLabel: 'Review',
          onAction: () => setState(() => _selectedIndex = 3),
          children: pendingProviders.isEmpty
              ? [_dashboardEmpty('No provider applications need review.')]
              : pendingProviders.take(3).map((provider) {
                  final name = (provider['name'] as String? ?? '').trim();
                  final org = (provider['businessName'] as String? ?? '')
                      .trim();
                  return _dashboardPreview(
                    icon: Icons.person_add_alt_1_rounded,
                    title: name.isEmpty ? 'Provider' : name,
                    subtitle: org.isEmpty ? 'Awaiting approval' : org,
                    onTap: () => setState(() => _selectedIndex = 3),
                  );
                }).toList(),
        ),
      ],
    );
  }

  Widget _dashboardHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: appMuted)),
    ],
  );

  Widget _dashboardSection({
    required String title,
    required int count,
    required String actionLabel,
    required VoidCallback onAction,
    required List<Widget> children,
  }) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F5F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: appTeal,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
        const Divider(height: 1),
        ...children,
      ],
    ),
  );

  Widget _dashboardPreview({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => ListTile(
    onTap: onTap,
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: appTeal, size: 21),
    ),
    title: Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right_rounded, color: appMuted),
  );

  Widget _dashboardEmpty(String message) => Padding(
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: appTeal),
        const SizedBox(width: 10),
        Expanded(
          child: Text(message, style: const TextStyle(color: appMuted)),
        ),
      ],
    ),
  );

  Widget _sectionPage({
    required String title,
    required String subtitle,
    required Widget child,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: appMuted)),
          ],
        ),
      ),
      Expanded(child: child),
    ],
  );

  Widget _providerList({
    required List<Map<String, dynamic>> providers,
    required String emptyMessage,
  }) {
    final rows = [...providers]
      ..sort((a, b) {
        final pendingA = a['verificationStatus'] == 'pending' ? 0 : 1;
        final pendingB = b['verificationStatus'] == 'pending' ? 0 : 1;
        return pendingA.compareTo(pendingB);
      });
    if (rows.isEmpty) {
      return _EmptyPanel(message: emptyMessage);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final provider = rows[index];
          final status =
              provider['verificationStatus']?.toString() ?? 'pending';
          final providerName = (provider['name'] as String? ?? '').trim();
          final organizationName = (provider['businessName'] as String? ?? '')
              .trim();
          final phone = (provider['phone'] as String? ?? '').trim();
          final serviceIds = provider['serviceIds'] is List
              ? (provider['serviceIds'] as List).map(_serviceName).join(', ')
              : '';
          final areas = provider['serviceAreas'] is List
              ? (provider['serviceAreas'] as List).join(', ')
              : '';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          providerName.isNotEmpty ? providerName : 'Provider',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                      _StatusPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (organizationName.isNotEmpty)
                    Text('Organization: $organizationName'),
                  if (phone.isNotEmpty) Text('Phone: $phone'),
                  if (serviceIds.isNotEmpty) Text('Services: $serviceIds'),
                  if (areas.isNotEmpty) Text('Service areas: $areas'),
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _verifyProvider(provider, 'verified'),
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy
                              ? null
                              : () => _verifyProvider(provider, 'rejected'),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _notificationsPage() => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            child: ListTile(
              leading: const Icon(
                Icons.notifications_active_outlined,
                color: appTeal,
              ),
              title: Text('$_notificationCount new notifications'),
              subtitle: Text(
                '$_newBookingRequestCount booking requests · '
                '$_newProviderRequestCount provider applications',
              ),
            ),
          ),
        ),
        TabBar(
          tabs: [
            Tab(text: 'Bookings ($_newBookingRequestCount)'),
            Tab(text: 'Providers ($_newProviderRequestCount)'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _orderList(
                orders: _orders
                    .where((row) => row['status'] == 'pending_assignment')
                    .toList(),
                emptyMessage: 'No new booking requests.',
              ),
              _providerList(
                providers: _providers
                    .where((row) => row['verificationStatus'] == 'pending')
                    .toList(),
                emptyMessage: 'No provider applications need review.',
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _adminUsersPage() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline, color: appTeal),
            title: const Text('Grant admin access by email'),
            subtitle: const Text(
              'The person must already have an account. Only an existing admin can grant this role.',
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _addAdminUser,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add administrator'),
          ),
        ),
      ),
      Expanded(
        child: _adminsLoading
            ? const Center(child: CircularProgressIndicator())
            : _adminUsers.isEmpty
            ? const _EmptyPanel(message: 'No administrators found.')
            : RefreshIndicator(
                onRefresh: _loadAdminUsers,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _adminUsers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final admin = _adminUsers[index];
                    final name = admin['name']?.toString().trim() ?? '';
                    final email = admin['email']?.toString().trim() ?? '';
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFDDF4EE),
                          child: Text(
                            name.isEmpty ? 'A' : name[0].toUpperCase(),
                            style: const TextStyle(color: appTeal),
                          ),
                        ),
                        title: Text(name.isEmpty ? 'Administrator' : name),
                        subtitle: Text(email.isEmpty ? 'Account' : email),
                      ),
                    );
                  },
                ),
              ),
      ),
    ],
  );

  Widget _orderList({
    List<Map<String, dynamic>>? orders,
    String emptyMessage = 'No bookings yet.',
  }) {
    final rows = [...(orders ?? _orders)]
      ..sort(
        (a, b) => (b[r'$createdAt']?.toString() ?? '').compareTo(
          a[r'$createdAt']?.toString() ?? '',
        ),
      );
    if (rows.isEmpty) return _EmptyPanel(message: emptyMessage);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final order = rows[index];
          final status = order['status']?.toString() ?? 'unknown';
          final canAssign =
              status == 'pending_assignment' || status == 'assigned';
          final scheduled = DateTime.tryParse(
            order['scheduledAt']?.toString() ?? '',
          )?.toLocal();
          final providerId = order['assignedProviderId']?.toString();
          final provider = _providers.firstWhere(
            (item) => item['userId'] == providerId,
            orElse: () => <String, dynamic>{},
          );
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order[r'$id']?.toString() ?? 'Booking',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _StatusPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order['serviceName'] ?? _serviceName(order['serviceId'])} - ${order['clientName'] as String? ?? 'Client'}',
                  ),
                  if (scheduled != null)
                    Text('Scheduled: ${_formatDate(scheduled)}'),
                  Text(
                    'Address: ${[order['address'], order['area'], order['city'], order['state'], order['pinCode']].whereType<String>().where((part) => part.isNotEmpty).join(', ')}',
                  ),
                  if (providerId != null && providerId.isNotEmpty)
                    Text(
                      'Assigned provider: ${(provider['name'] as String? ?? '').trim().isNotEmpty ? (provider['name'] as String).trim() : 'Provider'}',
                    ),
                  if (canAssign) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _assignOrder(order),
                      icon: const Icon(Icons.assignment_ind_outlined),
                      label: Text(
                        status == 'assigned'
                            ? 'Reassign provider'
                            : 'Assign provider',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GrantAdminDialog extends StatefulWidget {
  const _GrantAdminDialog();

  @override
  State<_GrantAdminDialog> createState() => _GrantAdminDialogState();
}

class _GrantAdminDialogState extends State<_GrantAdminDialog> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add administrator'),
    content: TextField(
      controller: _emailController,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(labelText: 'Account email'),
      onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () =>
            Navigator.of(context).pop(_emailController.text.trim()),
        child: const Text('Grant access'),
      ),
    ],
  );
}

class _AdminNameDialog extends StatefulWidget {
  const _AdminNameDialog({
    required this.initialName,
    required this.initials,
    required this.email,
  });

  final String initialName;
  final String initials;
  final String? email;

  @override
  State<_AdminNameDialog> createState() => _AdminNameDialogState();
}

class _AdminNameDialogState extends State<_AdminNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Admin profile'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFDDF4EE),
          child: Text(
            widget.initials,
            style: const TextStyle(
              color: appTeal,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (widget.email?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(widget.email!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Admin name'),
          onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        child: const Text('Save'),
      ),
    ],
  );
}

class _AssignProviderDialog extends StatefulWidget {
  const _AssignProviderDialog({
    required this.providers,
    required this.services,
  });
  final List<Map<String, dynamic>> providers;
  final List<Map<String, dynamic>> services;

  @override
  State<_AssignProviderDialog> createState() => _AssignProviderDialogState();
}

class _AssignProviderDialogState extends State<_AssignProviderDialog> {
  String? _selectedId;

  String _serviceName(dynamic serviceId) {
    for (final service in widget.services) {
      if (service[r'$id'] == serviceId) {
        return service['name'] as String? ?? 'Care service';
      }
    }
    return 'Care service';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Assign provider'),
    content: SizedBox(
      width: double.maxFinite,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .6,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: widget.providers.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final provider = widget.providers[index];
            final id = provider['userId'] as String;
            final availability = provider['isAvailable'] == true
                ? 'Available'
                : 'Unavailable (manual assignment)';
            final services = provider['serviceIds'] is List
                ? (provider['serviceIds'] as List).map(_serviceName).join(', ')
                : 'No services listed';
            final areas = provider['serviceAreas'] is List
                ? (provider['serviceAreas'] as List).join(', ')
                : 'No areas listed';
            final selected = id == _selectedId;
            return ListTile(
              selected: selected,
              onTap: () => setState(() => _selectedId = id),
              leading: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(
                (provider['name'] as String? ?? '').trim().isNotEmpty
                    ? (provider['name'] as String).trim()
                    : 'Provider',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '$availability\nServices: $services\nAreas: $areas',
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              isThreeLine: true,
              contentPadding: EdgeInsets.zero,
            );
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selectedId == null
            ? null
            : () => Navigator.pop(
                context,
                widget.providers.firstWhere(
                  (row) => row['userId'] == _selectedId,
                ),
              ),
        child: const Text('Assign'),
      ),
    ],
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'verified' || 'completed' || 'accepted' => appTeal,
      'rejected' || 'cancelled' || 'suspended' => Colors.red.shade700,
      _ => Colors.orange.shade800,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          status.replaceAll('_', ' '),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.accent = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent ? const Color(0xFFE1F4EF) : const Color(0xFFF0F3F3),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent ? appTeal : appInk, size: 19),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800, height: 1),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: appMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(message, style: const TextStyle(color: appMuted)),
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: Colors.red.shade700, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

String _message(Object error) {
  final text = error.toString();
  return text.startsWith('FormatException: ')
      ? text.substring('FormatException: '.length)
      : 'Could not complete this request. Please try again.';
}

String _formatDate(DateTime value) {
  final date =
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '$date, $hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
}
