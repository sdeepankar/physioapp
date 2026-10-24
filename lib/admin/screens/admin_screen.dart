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
  int _selectedIndex = 2;
  bool _showNotificationsPage = false;
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _services = [];
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
      return bookedTime != null && bookedTime.isAtSameMomentAs(requestedTime);
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: _showNotificationsPage
          ? IconButton(
              tooltip: 'Back to dashboard',
              onPressed: () => setState(() => _showNotificationsPage = false),
              icon: const Icon(Icons.arrow_back_rounded),
            )
          : null,
      title: Text(_showNotificationsPage ? 'Notifications' : 'Hi, $_adminName'),
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
                  : IndexedStack(
                      index: _selectedIndex,
                      children: [
                        _sectionPage(
                          title: 'Bookings',
                          subtitle: 'Track requests and assigned care visits.',
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
                                      row['verificationStatus'] == 'verified' &&
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
    bottomNavigationBar: _showNotificationsPage
        ? null
        : NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFDDF4EE),
            destinations: const [
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
                          (provider['name'] as String? ?? '').trim().isNotEmpty
                              ? (provider['name'] as String).trim()
                              : 'Provider',
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
