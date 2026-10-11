import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/support_config.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key, required this.onOpenBookings});

  final VoidCallback onOpenBookings;

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String? _launchingContact;

  static const _issues = <String>[
    'Booking confirmation or status',
    'Reschedule or cancel',
    'Professional is late or did not arrive',
    'Service or price question',
    'Payment question',
    'Something else',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Help & Support'),
      backgroundColor: appCanvas,
    ),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, _) => Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _introCard(),
                const SizedBox(height: 24),
                _sectionTitle('Quick help'),
                const SizedBox(height: 10),
                _quickLink(
                  icon: Icons.calendar_month_outlined,
                  title: 'My bookings',
                  subtitle: 'View booking details and current status',
                  onTap: _openBookings,
                ),
                for (final issue in _issues.take(5))
                  _quickLink(
                    icon: _issueIcon(issue),
                    title: issue,
                    subtitle: 'Tell us what you need help with',
                    onTap: () => _openIssueReport(prefilledIssue: issue),
                  ),
                const SizedBox(height: 22),
                _sectionTitle('Frequently asked questions'),
                const SizedBox(height: 10),
                for (final faq in _faqs) _faqTile(faq.$1, faq.$2),
                const SizedBox(height: 22),
                _sectionTitle('Contact us'),
                const SizedBox(height: 10),
                _contactTile(
                  keyName: 'phone',
                  icon: Icons.call_outlined,
                  title: 'Phone',
                  configuredValue: supportConfiguration.phoneNumber,
                  uriBuilder: (value) => Uri(scheme: 'tel', path: value),
                ),
                _contactTile(
                  keyName: 'whatsapp',
                  icon: Icons.chat_outlined,
                  title: 'WhatsApp',
                  configuredValue: supportConfiguration.whatsAppNumber,
                  uriBuilder: (value) => Uri.https('wa.me', value, {
                    'text': 'Hello Deep Care, I need help with a booking.',
                  }),
                ),
                _contactTile(
                  keyName: 'email',
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  configuredValue: supportConfiguration.emailAddress,
                  uriBuilder: (value) => Uri(
                    scheme: 'mailto',
                    path: value,
                    queryParameters: {
                      'subject': 'Deep Care support',
                      'body': 'Hello Deep Care, I need help with a booking.',
                    },
                  ),
                ),
                const SizedBox(height: 22),
                _emergencyNotice(),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _openIssueReport(),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Report an issue'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: appTeal,
                    side: const BorderSide(color: appTeal),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _introCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFE5F4F0),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.support_agent_rounded, color: appTeal, size: 28),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How can we help?',
                style: TextStyle(
                  color: appInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Find answers about your care bookings, payments, and using Deep Care.',
                style: TextStyle(color: appMuted, height: 1.45, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      color: appInk,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _quickLink({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ListTile(
      onTap: onTap,
      leading: _iconBox(icon),
      title: Text(
        title,
        style: const TextStyle(color: appInk, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: appMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: appMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    ),
  );

  Widget _faqTile(String question, String answer) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      iconColor: appTeal,
      collapsedIconColor: appMuted,
      title: Text(
        question,
        style: const TextStyle(
          color: appInk,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            answer,
            style: const TextStyle(color: appMuted, height: 1.5, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _contactTile({
    required String keyName,
    required IconData icon,
    required String title,
    required String? configuredValue,
    required Uri Function(String value) uriBuilder,
  }) {
    final isAvailable = configuredValue?.trim().isNotEmpty == true;
    final isLaunching = _launchingContact == keyName;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        enabled: isAvailable && !isLaunching,
        onTap: isAvailable
            ? () => _launchContact(keyName, uriBuilder(configuredValue!.trim()))
            : null,
        leading: _iconBox(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isAvailable ? 'Contact Deep Care support' : 'Not available yet',
          style: const TextStyle(color: appMuted),
        ),
        trailing: isLaunching
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isAvailable ? Icons.open_in_new_rounded : Icons.lock_outline,
                color: appMuted,
                size: 19,
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      ),
    );
  }

  Widget _emergencyNotice() => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF1ED),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF2C7BD)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.emergency_outlined, color: Color(0xFFB94135)),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Immediate emergency?',
                style: TextStyle(
                  color: Color(0xFF8E3028),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Deep Care support is not an emergency response service. For immediate emergencies in India, call 112.',
          style: TextStyle(color: appInk, height: 1.45, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _callEmergencyNumber,
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Call 112'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB94135),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _iconBox(IconData icon) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: const Color(0xFFE5F4F0),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: appTeal, size: 21),
  );

  IconData _issueIcon(String issue) => switch (issue) {
    'Booking confirmation or status' => Icons.receipt_long_outlined,
    'Reschedule or cancel' => Icons.event_busy_outlined,
    'Professional is late or did not arrive' => Icons.schedule_outlined,
    'Service or price question' => Icons.medical_services_outlined,
    _ => Icons.payments_outlined,
  };

  Future<void> _openIssueReport({String? prefilledIssue}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: appCanvas,
      builder: (context) =>
          _IssueReportSheet(issues: _issues, prefilledIssue: prefilledIssue),
    );
  }

  void _openBookings() {
    Navigator.of(context).pop();
    widget.onOpenBookings();
  }

  Future<void> _launchContact(String keyName, Uri uri) async {
    setState(() => _launchingContact = keyName);
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showMessage('Could not open that app. Please try again later.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not open that app. Please try again later.');
      }
    } finally {
      if (mounted) setState(() => _launchingContact = null);
    }
  }

  Future<void> _callEmergencyNumber() async {
    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: '112'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showMessage('Could not open the phone app.');
    } catch (_) {
      if (mounted) _showMessage('Could not open the phone app.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static const _faqs = <(String, String)>[
    (
      'How do I book a home visit?',
      'Choose a service, review its details, select a date and time, add the visit address, then review and confirm. The demo booking stays in the current app session; it is not sent to a care provider.',
    ),
    (
      'Which areas do you serve?',
      'The prototype does not have a verified service-area list yet. Use location lookup to fill an address, or enter the visit address manually; availability is not checked online.',
    ),
    (
      'How do I change or cancel a booking?',
      'Open My bookings and select a booking to view its details. The current prototype supports cancelling a demo booking; rescheduling is not available yet.',
    ),
    (
      'How does payment work?',
      'The UPI flow is currently a demo. It does not contact a payment provider or charge you. Booking and payment states are only part of this local prototype.',
    ),
    (
      'Why does the app need location access?',
      'Location can help fill the visit address. You can deny permission and enter the address manually. Location lookup requires location services and permission on your device.',
    ),
    (
      'What should I do if the professional is late?',
      'Check the booking details and use the issue report to prepare the booking reference and a short description. Support contacts are shown when they have been configured. For an immediate emergency, call 112 in India.',
    ),
  ];
}

class _IssueReportSheet extends StatefulWidget {
  const _IssueReportSheet({required this.issues, this.prefilledIssue});

  final List<String> issues;
  final String? prefilledIssue;

  @override
  State<_IssueReportSheet> createState() => _IssueReportSheetState();
}

class _IssueReportSheetState extends State<_IssueReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _bookingReferenceController = TextEditingController();
  final _descriptionController = TextEditingController();
  late String? _selectedIssue = widget.prefilledIssue;

  @override
  void dispose() {
    _bookingReferenceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      20 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D9D8),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Report an issue',
              style: TextStyle(
                color: appInk,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Choose a topic and add a booking reference or short description if helpful. Do not include detailed medical information.',
              style: TextStyle(color: appMuted, height: 1.45, fontSize: 13),
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: _selectedIssue,
              decoration: _fieldDecoration('What do you need help with?'),
              items: [
                for (final issue in widget.issues)
                  DropdownMenuItem(value: issue, child: Text(issue)),
              ],
              onChanged: (value) => setState(() => _selectedIssue = value),
              validator: (value) => value == null ? 'Choose an issue' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bookingReferenceController,
              textInputAction: TextInputAction.next,
              maxLength: 40,
              decoration: _fieldDecoration('Booking reference (optional)'),
            ),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 5,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: _fieldDecoration('Short description (optional)'),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: _reviewIssue,
              style: FilledButton.styleFrom(
                backgroundColor: appTeal,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Review issue'),
            ),
            const SizedBox(height: 11),
            const Text(
              'This app has no support submission service yet. Reviewing this issue will not send a request or create a ticket.',
              textAlign: TextAlign.center,
              style: TextStyle(color: appMuted, height: 1.4, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  void _reviewIssue() {
    if (_formKey.currentState?.validate() != true) return;
    final details = <String>[
      'Issue: $_selectedIssue',
      if (_bookingReferenceController.text.trim().isNotEmpty)
        'Booking reference: ${_bookingReferenceController.text.trim()}',
      if (_descriptionController.text.trim().isNotEmpty)
        'Description: ${_descriptionController.text.trim()}',
    ].join('\n\n');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review your issue'),
        content: Text(
          '$details\n\nYour issue has not been sent. Support requests are not available in this prototype yet.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(this.context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
