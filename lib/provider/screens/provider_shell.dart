import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_theme.dart';
import '../../services/appwrite_service.dart';
import '../services/provider_service.dart';

class ProviderAuthGate extends StatefulWidget {
  const ProviderAuthGate({super.key});

  @override
  State<ProviderAuthGate> createState() => _ProviderAuthGateState();
}

class _ProviderAuthGateState extends State<ProviderAuthGate> {
  bool _checking = true;
  bool _signedIn = false;
  String? _error;
  Map<String, dynamic>? _status;
  String _draftName = '';
  String _draftPhone = '';

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final signedIn = await AppwriteService.instance.isSignedIn();
      if (!mounted) return;
      if (signedIn) {
        setState(() => _signedIn = true);
        await _loadStatus();
      } else {
        setState(() => _checking = false);
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
          _checking = false;
        });
      }
    }
  }

  Future<void> _loadStatus() async {
    if (mounted) {
      setState(() {
        _checking = true;
        _error = null;
      });
    }
    try {
      final status = await ProviderService.instance.getStatus();
      if (!mounted) return;
      setState(() {
        _status = status;
        final user = status['userProfile'];
        if (user is Map) {
          _draftName = user['name']?.toString() ?? _draftName;
          _draftPhone = user['phone']?.toString() ?? _draftPhone;
        }
        _checking = false;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
          _checking = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await AppwriteService.instance.signOut();
    } on Object {
      // Clear the local gate even if the server session has already expired.
    }
    if (!mounted) return;
    setState(() {
      _signedIn = false;
      _status = null;
      _error = null;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_signedIn) {
      return ProviderLoginScreen(
        onSignedIn: (name, phone) {
          _draftName = name;
          _draftPhone = phone;
          setState(() => _signedIn = true);
          _loadStatus();
        },
      );
    }
    if (_error != null) {
      return _MessageScreen(
        title: 'Could not load provider account',
        message: _error!,
        onRetry: _loadStatus,
        onSignOut: _signOut,
      );
    }
    final role = _status?['role'];
    if (role == 'admin') {
      return _MessageScreen(
        title: 'Provider account required',
        message: 'This account has admin access. Sign out and use a client or provider account to continue.',
        onSignOut: _signOut,
      );
    }
    final providerProfile = _status?['providerProfile'];
    if (role == 'provider' && providerProfile is Map) {
      return ProviderDashboard(
        profile: Map<String, dynamic>.from(providerProfile),
        userProfile: _userProfileFromStatus(_status),
        onSignOut: _signOut,
      );
    }
    return ProviderApplicationScreen(
      initialName: _draftName,
      initialPhone: _draftPhone,
      initialProfile: providerProfile is Map
          ? Map<String, dynamic>.from(providerProfile)
          : null,
      onApplied: (_) => _loadStatus(),
      onSignOut: _signOut,
    );
  }
}

Map<String, dynamic> _userProfileFromStatus(Map<String, dynamic>? status) {
  final profile = status?['userProfile'];
  return profile is Map ? Map<String, dynamic>.from(profile) : {};
}

class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({required this.onSignedIn, super.key});

  final void Function(String name, String phone) onSignedIn;

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _signup = false;
  bool _busy = false;
  String? _userId;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final appwrite = AppwriteService.instance;
      final userId = _signup
          ? await appwrite.sendEmailVerificationCode(email: _email.text)
          : await appwrite.sendLoginEmailVerificationCode(email: _email.text);
      if (mounted) setState(() => _userId = userId);
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final userId = _userId;
    if (userId == null || _code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the one-time code sent to your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppwriteService.instance.verifyEmailCode(
        userId: userId,
        code: _code.text,
        name: _signup ? _name.text.trim() : null,
      );
      widget.onSignedIn(_name.text.trim(), _phone.text.trim());
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changeMode(bool signup) => setState(() {
    _signup = signup;
    _userId = null;
    _code.clear();
    _error = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.medical_services_outlined,
                        size: 52,
                        color: appTeal,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _signup ? 'Join Deep Care' : 'Provider sign in',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: appInk,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _signup
                            ? 'Create an account, then submit your provider profile for admin approval.'
                            : 'Sign in to manage your provider profile and assigned visits.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: appMuted),
                      ),
                      const SizedBox(height: 24),
                      if (_signup) ...[
                        TextFormField(
                          controller: _name,
                          enabled: !_busy && _userId == null,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) =>
                              _signup && (value?.trim().isEmpty ?? true)
                              ? 'Enter your name.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          enabled: !_busy && _userId == null,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (value) =>
                              _signup && (value?.trim().isEmpty ?? true)
                              ? 'Enter your phone number.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        enabled: !_busy && _userId == null,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          return email.contains('@') && email.contains('.')
                              ? null
                              : 'Enter a valid email.';
                        },
                      ),
                      if (_userId != null) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _code,
                          enabled: !_busy,
                          keyboardType: TextInputType.number,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          decoration: const InputDecoration(
                            labelText: 'Email code',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : (_userId == null ? _sendCode : _verifyCode),
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _userId == null
                                    ? 'Send email code'
                                    : 'Verify and continue',
                              ),
                      ),
                      if (_userId == null)
                        TextButton(
                          onPressed: _busy ? null : () => _changeMode(!_signup),
                          child: Text(
                            _signup
                                ? 'Already have an account? Sign in'
                                : 'New provider? Create an account',
                          ),
                        ),
                      if (_userId != null)
                        TextButton(
                          onPressed: _busy ? null : () => _changeMode(_signup),
                          child: const Text('Change email or resend code'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class ProviderApplicationScreen extends StatefulWidget {
  const ProviderApplicationScreen({
    required this.initialName,
    required this.initialPhone,
    required this.initialProfile,
    this.onApplied,
    required this.onSignOut,
    super.key,
  });

  final String initialName;
  final String initialPhone;
  final Map<String, dynamic>? initialProfile;
  final ValueChanged<Map<String, dynamic>>? onApplied;
  final VoidCallback onSignOut;

  @override
  State<ProviderApplicationScreen> createState() =>
      _ProviderApplicationScreenState();
}

class _ProviderApplicationScreenState extends State<ProviderApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _businessName;
  late final TextEditingController _areas;
  final Set<String> _selectedServices = {};
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile ?? {};
    _name = TextEditingController(text: widget.initialName);
    _phone = TextEditingController(text: widget.initialPhone);
    _businessName = TextEditingController(
      text: profile['businessName']?.toString() ?? '',
    );
    final areas = profile['serviceAreas'];
    _areas = TextEditingController(text: areas is List ? areas.join(', ') : '');
    final services = profile['serviceIds'];
    if (services is List) {
      _selectedServices.addAll(services.map((item) => item.toString()));
    }
    _loadServices();
    _loadAccountName();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _businessName.dispose();
    _areas.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services = await ProviderService.instance.listServices();
      if (mounted) {
        setState(() {
          _services = services;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadAccountName() async {
    if (_name.text.trim().isNotEmpty) return;
    try {
      final user = await AppwriteService.instance.getCurrentUser();
      if (mounted && _name.text.trim().isEmpty) {
        setState(() => _name.text = user.name);
      }
    } on Object {
      // The provider can enter their name directly if the account has none.
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedServices.isEmpty) {
      setState(() => _error = 'Choose at least one service you provide.');
      return;
    }
    final areas = _areas.text
        .split(RegExp(r'[,\n]'))
        .map((area) => area.trim())
        .where((area) => area.isNotEmpty)
        .toSet()
        .toList();
    if (areas.isEmpty) {
      setState(
        () => _error = 'Add at least one city, area, state, or PIN code.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final profile = await ProviderService.instance.apply(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        businessName: _businessName.text.trim(),
        serviceIds: _selectedServices.toList(),
        serviceAreas: areas,
      );
      if (!mounted) return;
      final callback = widget.onApplied;
      if (callback != null) {
        callback(profile);
      } else {
        Navigator.of(context).pop(profile);
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Provider application'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.onSignOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const _InfoBanner(
                    icon: Icons.verified_user_outlined,
                    title: 'Apply to provide care',
                    message: 'Your profile will be reviewed by Deep Care admin. You can receive assigned bookings after approval.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Your name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _businessName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Business or provider name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Services you provide',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (_services.isEmpty)
                    const Text(
                      'No active services are available. Contact admin.',
                      style: TextStyle(color: appMuted),
                    )
                  else
                    ..._services.map((service) {
                      final id = service[r'$id']?.toString() ?? '';
                      final name =
                          service['name']?.toString() ?? 'Care service';
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name),
                        value: _selectedServices.contains(id),
                        onChanged: _saving || id.isEmpty
                            ? null
                            : (selected) => setState(() {
                                if (selected == true) {
                                  _selectedServices.add(id);
                                } else {
                                  _selectedServices.remove(id);
                                }
                              }),
                      );
                    }),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _areas,
                    minLines: 2,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Service areas',
                      hintText: 'For example: Delhi, Noida, 110001',
                      helperText: 'Separate multiple cities, areas, states, or PIN codes with commas or new lines.',
                      border: OutlineInputBorder(),
                    ),
                    validator: _required,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving || _services.isEmpty ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _saving
                          ? 'Submitting…'
                          : (widget.initialProfile == null
                                ? 'Submit for approval'
                                : 'Update and resubmit'),
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({
    required this.profile,
    required this.userProfile,
    required this.onSignOut,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic> userProfile;
  final VoidCallback onSignOut;

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  late Map<String, dynamic> _profile = widget.profile;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;
  bool _working = false;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _loadServiceCatalog();
  }

  Future<void> _loadServiceCatalog() async {
    try {
      final services = await ProviderService.instance.listServices();
      if (mounted) setState(() => _services = services);
    } on Object {
      // Keep stored service IDs visible if the catalog is temporarily unavailable.
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await ProviderService.instance.getStatus();
      final currentProfile = status['providerProfile'];
      if (currentProfile is! Map) {
        throw const FormatException(
          'Your provider profile could not be found.',
        );
      }
      final profile = Map<String, dynamic>.from(currentProfile);
      final orders = profile['verificationStatus'] == 'verified'
          ? await ProviderService.instance.listAssignedOrders()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _profile = profile;
          _orders = orders;
          _loading = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _error = _errorMessage(error);
          _loading = false;
        });
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() => _working = true);
    try {
      final profile = await ProviderService.instance.setAvailability(value);
      if (mounted) setState(() => _profile = profile);
    } on Object catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _performOrderAction(
    Map<String, dynamic> order,
    String action,
  ) async {
    final orderId = order[r'$id']?.toString() ?? '';
    if (orderId.isEmpty) return;
    if (action == 'reject') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Decline this booking?'),
          content: const Text(
            'Deep Care will offer the booking to another available provider. If nobody is available, it will return to admin for manual assignment.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep booking'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Decline'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    setState(() => _working = true);
    try {
      final response = await ProviderService.instance.updateOrder(
        orderId,
        action,
      );
      await _loadOrders();
      if (!mounted) return;
      if (response['manualInterventionRequired'] == true) {
        _showMessage(
          'No other provider was available. The booking has returned to admin.',
        );
      } else if (response['reassigned'] == true) {
        _showMessage(
          'The booking was reassigned to another available provider.',
        );
      } else {
        _showMessage('Booking updated.');
      }
    } on Object catch (error) {
      if (mounted) _showMessage(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _editApplication() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => ProviderApplicationScreen(
          initialName: widget.userProfile['name']?.toString() ?? '',
          initialPhone: widget.userProfile['phone']?.toString() ?? '',
          initialProfile: _profile,
          onApplied: null,
          onSignOut: widget.onSignOut,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() {
        _profile = updated;
        _tab = 1;
      });
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final verified = _profile['verificationStatus'] == 'verified';
    final pending = _profile['verificationStatus'] == 'pending';
    return Scaffold(
      appBar: AppBar(
        title: Text(_tab == 0 ? 'My bookings' : 'Provider profile'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _working ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: _tab == 0
            ? _bookingsBody(verified, pending)
            : _profileBody(verified, pending),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _bookingsBody(bool verified, bool pending) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!verified)
            _InfoBanner(
              icon: pending ? Icons.hourglass_top : Icons.info_outline,
              title: pending
                  ? 'Application under review'
                  : 'Provider approval required',
              message: pending
                  ? 'Admin must approve your profile before you can turn on availability and receive bookings.'
                  : 'Update your provider profile and submit it for admin approval.',
              actionLabel: pending ? null : 'Update application',
              onAction: pending ? null : _editApplication,
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorPanel(message: _error!, onRetry: _loadOrders),
          ],
          const SizedBox(height: 12),
          Text(
            'Assigned to you',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, color: appInk),
          ),
          const SizedBox(height: 10),
          if (_orders.isEmpty)
            const _EmptyPanel(
              title: 'No assigned bookings',
              message:
                  'New bookings assigned by Deep Care admin will appear here.',
            )
          else
            ..._orders.map(
              (order) => ProviderOrderCard(
                order: order,
                enabled: verified && !_working,
                onAction: (action) => _performOrderAction(order, action),
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileBody(bool verified, bool pending) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _InfoBanner(
        icon: verified
            ? Icons.verified_outlined
            : (pending ? Icons.hourglass_top : Icons.info_outline),
        title: verified
            ? 'Provider verified'
            : (pending
                  ? 'Application under review'
                  : 'Application needs attention'),
        message: verified
            ? 'Your profile is approved. Turn availability on when you can accept care visits.'
            : (pending
                  ? 'Your provider profile is waiting for admin approval.'
                  : 'Edit your details and resubmit your application for review.'),
        actionLabel: pending ? null : 'Edit provider profile',
        onAction: pending ? null : _editApplication,
      ),
      const SizedBox(height: 16),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.medical_services_outlined),
              ),
              title: Text(_profile['businessName']?.toString() ?? 'Provider'),
              subtitle: Text(widget.userProfile['name']?.toString() ?? ''),
            ),
            if ((widget.userProfile['phone']?.toString() ?? '').isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: Text(widget.userProfile['phone'].toString()),
              ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Available for bookings'),
              subtitle: Text(
                verified
                    ? 'Admin can assign matching services in your service areas.'
                    : 'Availability turns on after admin approval.',
              ),
              value: verified && _profile['isAvailable'] == true,
              onChanged: verified && !_working ? _toggleAvailability : null,
            ),
            ListTile(
              leading: const Icon(Icons.health_and_safety_outlined),
              title: const Text('Verification'),
              trailing: _StatusPill(
                status: _profile['verificationStatus']?.toString() ?? 'pending',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: const Text('Average rating'),
              trailing: Text(
                (_profile['averageRating'] as num?)?.toStringAsFixed(1) ?? '—',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Completed visits'),
              trailing: Text((_profile['completedOrderCount'] ?? 0).toString()),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Service areas'),
              subtitle: Text(
                _asStringList(_profile['serviceAreas']).join(', '),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Services'),
              subtitle: Text(_serviceNames(_profile['serviceIds'])),
            ),
          ],
        ),
      ),
    ],
  );

  String _serviceNames(dynamic ids) {
    final serviceIds = _asStringList(ids);
    return serviceIds
        .map((id) {
          for (final service in _services) {
            if (service[r'$id'] == id) {
              return service['name']?.toString() ?? id;
            }
          }
          return id;
        })
        .join(', ');
  }
}

class ProviderOrderCard extends StatelessWidget {
  const ProviderOrderCard({
    required this.order,
    required this.enabled,
    required this.onAction,
    super.key,
  });

  final Map<String, dynamic> order;
  final bool enabled;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'assigned';
    final actions = _actionsFor(status);
    final address = [
      order['address'],
      order['area'],
      order['city'],
      order['state'],
      order['pinCode'],
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
    final scheduled = _formatDate(order['scheduledAt']?.toString());
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
                    order['serviceName']?.toString() ?? 'Care visit',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800, color: appInk),
                  ),
                ),
                _StatusPill(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Booking ${order[r'$id'] ?? ''}',
              style: const TextStyle(color: appMuted, fontSize: 12),
            ),
            if (scheduled.isNotEmpty) ...[
              const SizedBox(height: 10),
              _DetailRow(icon: Icons.schedule_outlined, text: scheduled),
            ],
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(icon: Icons.location_on_outlined, text: address),
            ],
            if ((order['clientName']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.person_outline,
                text: order['clientName'].toString(),
              ),
            ],
            if ((order['clientPhone']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => launchUrl(
                  Uri(scheme: 'tel', path: order['clientPhone'].toString()),
                ),
                icon: const Icon(Icons.call_outlined),
                label: Text('Call ${order['clientPhone']}'),
              ),
            ] else if (order['clientUserId'] != null) ...[
              const SizedBox(height: 8),
              _DetailRow(
                icon: Icons.person_outline,
                text: 'Client reference: ${order['clientUserId']}',
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map(
                      (action) => action == 'reject'
                          ? OutlinedButton.icon(
                              onPressed: enabled
                                  ? () => onAction(action)
                                  : null,
                              icon: const Icon(Icons.close),
                              label: const Text('Decline'),
                            )
                          : FilledButton.icon(
                              onPressed: enabled
                                  ? () => onAction(action)
                                  : null,
                              icon: Icon(_actionIcon(action)),
                              label: Text(_actionLabel(action)),
                            ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageScreen extends StatelessWidget {
  const _MessageScreen({
    required this.title,
    required this.message,
    this.onRetry,
    required this.onSignOut,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.medical_services_outlined,
                size: 52,
                color: appTeal,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: appMuted),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Try again'),
                ),
              ],
              TextButton(onPressed: onSignOut, child: const Text('Sign out')),
            ],
          ),
        ),
      ),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE4F4F0),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: appTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: appInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(message, style: const TextStyle(color: appMuted)),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'verified' || 'completed' => appTeal,
      'rejected' || 'cancelled' => Colors.red.shade700,
      'in_progress' || 'out_for_service' => Colors.deepOrange.shade700,
      _ => Colors.blueGrey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: appMuted),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: const TextStyle(color: appInk)),
      ),
    ],
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 18),
    child: Column(
      children: [
        const Icon(Icons.event_available_outlined, size: 42, color: appMuted),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: appInk),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: appMuted),
        ),
      ],
    ),
  );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline, color: Colors.red),
      title: const Text('Could not load bookings'),
      subtitle: Text(message),
      trailing: IconButton(onPressed: onRetry, icon: const Icon(Icons.refresh)),
    ),
  );
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String _errorMessage(Object error) => error is FormatException
    ? error.message
    : error.toString().replaceFirst('Exception: ', '');

List<String> _asStringList(dynamic value) =>
    value is List ? value.map((item) => item.toString()).toList() : const [];

String _statusLabel(String value) => switch (value) {
  'pending_assignment' => 'Awaiting provider',
  'out_for_service' => 'On the way',
  'in_progress' => 'In progress',
  'verified' => 'Verified',
  'pending' => 'Pending review',
  'rejected' => 'Needs updates',
  'accepted' => 'Accepted',
  'assigned' => 'New booking',
  'completed' => 'Completed',
  'cancelled' => 'Cancelled',
  _ => value.replaceAll('_', ' '),
};

List<String> _actionsFor(String status) => switch (status) {
  'assigned' => ['accept', 'reject'],
  'accepted' => ['out-for-service'],
  'out_for_service' => ['start'],
  'in_progress' => ['complete'],
  _ => const [],
};

String _actionLabel(String action) => switch (action) {
  'accept' => 'Accept',
  'out-for-service' => 'I’m on my way',
  'start' => 'Start visit',
  'complete' => 'Complete visit',
  _ => action,
};

IconData _actionIcon(String action) => switch (action) {
  'accept' => Icons.check,
  'out-for-service' => Icons.directions_walk_outlined,
  'start' => Icons.play_arrow,
  'complete' => Icons.task_alt,
  _ => Icons.arrow_forward,
};

String _formatDate(String? value) {
  if (value == null) return '';
  final date = DateTime.tryParse(value)?.toLocal();
  if (date == null) return '';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day} ${months[date.month - 1]} ${date.year} · $hour:$minute $period';
}
