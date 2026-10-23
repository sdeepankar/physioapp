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

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
      _showMessage(
        'No verified, available provider matches this service and area.',
      );
      return;
    }
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AssignProviderDialog(providers: candidates),
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
    final serviceId = order['serviceId'];
    final targets =
        [order['area'], order['city'], order['state'], order['pinCode']]
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .map((value) => value.toLowerCase())
            .toList();
    return _providers.where((provider) {
      if (provider['verificationStatus'] != 'verified' ||
          provider['isAvailable'] != true) {
        return false;
      }
      final serviceIds = provider['serviceIds'];
      final areas = provider['serviceAreas'];
      if (serviceIds is! List ||
          !serviceIds.contains(serviceId) ||
          areas is! List) {
        return false;
      }
      return areas.any((area) {
        final value = area.toString().toLowerCase().trim();
        return value == '*' ||
            value == 'all' ||
            targets.any(
              (target) => value.contains(target) || target.contains(value),
            );
      });
    }).toList();
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin dashboard'),
      actions: [
        IconButton(
          onPressed: _signOut,
          tooltip: 'Sign out',
          icon: const Icon(Icons.logout),
        ),
      ],
      bottom: TabBar(
        controller: _tabs,
        tabs: [
          Tab(
            text:
                'Providers (${_providers.where((row) => row['verificationStatus'] == 'pending').length})',
          ),
          Tab(text: 'Bookings (${_orders.length})'),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _ErrorPanel(message: _error!, onRetry: _load)
        : Stack(
            children: [
              TabBarView(
                controller: _tabs,
                children: [_providerList(), _orderList()],
              ),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
  );

  Widget _providerList() {
    final rows = [..._providers]
      ..sort((a, b) {
        final pendingA = a['verificationStatus'] == 'pending' ? 0 : 1;
        final pendingB = b['verificationStatus'] == 'pending' ? 0 : 1;
        return pendingA.compareTo(pendingB);
      });
    if (rows.isEmpty) {
      return const _EmptyPanel(message: 'No provider profiles yet.');
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
                          provider['businessName'] as String? ?? 'Provider',
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
                  Text('Account ID: ${provider['userId'] ?? '—'}'),
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

  Widget _orderList() {
    final rows = [..._orders]
      ..sort(
        (a, b) => (b[r'$createdAt']?.toString() ?? '').compareTo(
          a[r'$createdAt']?.toString() ?? '',
        ),
      );
    if (rows.isEmpty) return const _EmptyPanel(message: 'No bookings yet.');
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
                    '${order['serviceName'] ?? _serviceName(order['serviceId'])} • ${order['clientUserId'] ?? ''}',
                  ),
                  if (scheduled != null)
                    Text('Scheduled: ${_formatDate(scheduled)}'),
                  Text(
                    'Address: ${[order['address'], order['area'], order['city'], order['state'], order['pinCode']].whereType<String>().where((part) => part.isNotEmpty).join(', ')}',
                  ),
                  if (providerId != null && providerId.isNotEmpty)
                    Text(
                      'Assigned provider: ${provider['businessName'] ?? providerId}',
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

class _AssignProviderDialog extends StatefulWidget {
  const _AssignProviderDialog({required this.providers});
  final List<Map<String, dynamic>> providers;

  @override
  State<_AssignProviderDialog> createState() => _AssignProviderDialogState();
}

class _AssignProviderDialogState extends State<_AssignProviderDialog> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Assign provider'),
    content: DropdownButtonFormField<String>(
      initialValue: _selectedId,
      decoration: const InputDecoration(
        labelText: 'Verified available provider',
      ),
      items: widget.providers.map((provider) {
        final id = provider['userId'] as String;
        final title =
            '${provider['businessName'] ?? 'Provider'} • ${provider['serviceAreas'] is List ? (provider['serviceAreas'] as List).join(', ') : ''}';
        return DropdownMenuItem(
          value: id,
          child: Text(title, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedId = value),
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
