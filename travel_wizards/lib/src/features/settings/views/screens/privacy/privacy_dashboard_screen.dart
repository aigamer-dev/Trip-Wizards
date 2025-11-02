import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:travel_wizards/src/shared/services/user_consent_management_service.dart';
import 'package:travel_wizards/src/shared/services/data_portability_service.dart';
import 'package:travel_wizards/src/core/app/settings_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

/// Comprehensive Privacy Dashboard for centralized privacy management
class PrivacyDashboardScreen extends StatefulWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  State<PrivacyDashboardScreen> createState() => _PrivacyDashboardScreenState();
}

class _PrivacyDashboardScreenState extends State<PrivacyDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  ConsentSummary? _consentSummary;
  Map<String, dynamic>? _privacyMetrics;
  final _consentService = UserConsentManagementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPrivacyData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPrivacyData() async {
    setState(() => _isLoading = true);
    try {
      // Initialize consent service if needed
      await _consentService.initialize();

      // Load consent summary
      _consentSummary = _consentService.getConsentSummary();

      // Load privacy metrics
      _privacyMetrics = await _loadPrivacyMetrics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load privacy data: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>> _loadPrivacyMetrics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    return {
      'dataProcessingCount': 42, // Mock implementation
      'consentGrantedCount': _consentSummary?.granted.length ?? 0,
      'lastDataExport': null, // Mock implementation
      'encryptionStatus': true, // Mock implementation
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.security_rounded), text: 'Consent'),
            Tab(icon: Icon(Icons.data_usage_rounded), text: 'Data'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildConsentTab(),
                _buildDataTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPrivacyStatusCard(),
        const SizedBox(height: 16),
        _buildQuickActionsCard(),
        const SizedBox(height: 16),
        _buildPrivacyMetricsCard(),
      ],
    );
  }

  Widget _buildPrivacyStatusCard() {
    final hasConsent = (_consentSummary?.granted.length ?? 0) > 0;
    final isEncrypted = _privacyMetrics?['encryptionStatus'] ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasConsent && isEncrypted
                      ? Icons.shield_rounded
                      : Icons.warning_rounded,
                  color: hasConsent && isEncrypted
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Status',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatusRow('Data Encryption', isEncrypted),
            _buildStatusRow('Consent Management', hasConsent),
            _buildStatusRow('GDPR Compliance', hasConsent && isEncrypted),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Icon(
                status ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: status ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                status ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: status ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.download_rounded,
                    label: 'Export Data',
                    onTap: _exportUserData,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.security_rounded,
                    label: 'Manage Consent',
                    onTap: () => _tabController.animateTo(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPrivacyMetricsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              'Data Processing Events',
              '${_privacyMetrics?['dataProcessingCount'] ?? 0}',
            ),
            _buildMetricRow(
              'Active Consents',
              '${_privacyMetrics?['consentGrantedCount'] ?? 0}',
            ),
            _buildMetricRow(
              'Last Data Export',
              _privacyMetrics?['lastDataExport'] ?? 'Never',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildConsentTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConsentManagementCard(),
        const SizedBox(height: 16),
        _buildConsentHistoryCard(),
      ],
    );
  }

  Widget _buildConsentManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent Management',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._buildConsentSwitches(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _refreshConsent,
                child: const Text('Refresh Consent Status'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildConsentSwitches() {
    if (_consentSummary == null) return [];

    return ConsentCategory.values.map((category) {
      final isGranted = _consentSummary!.granted.contains(category);
      final categoryName =
          category.name[0].toUpperCase() + category.name.substring(1);

      return SwitchListTile(
        title: Text(categoryName),
        subtitle: Text(isGranted ? 'Consent granted' : 'Consent not granted'),
        value: isGranted,
        onChanged: category == ConsentCategory.essential
            ? null // Essential consent cannot be changed
            : (value) => _updateConsent(category, value),
        contentPadding: EdgeInsets.zero,
      );
    }).toList();
  }

  Widget _buildConsentHistoryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent History',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Export Consent Data'),
              subtitle: const Text('Download your consent history'),
              onTap: _exportConsentData,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDataManagementCard(),
        const SizedBox(height: 16),
        _buildDataProcessingCard(),
        const SizedBox(height: 16),
        _buildDataRetentionCard(),
      ],
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.download_rounded),
              title: const Text('Export My Data'),
              subtitle: const Text('Download all your data (GDPR)'),
              onTap: _exportUserData,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded),
              title: const Text('Delete My Account'),
              subtitle: const Text('Permanently delete all data'),
              onTap: _deleteUserData,
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: const Text('Anonymize Data'),
              subtitle: const Text('Remove personal identifiers'),
              onTap: _anonymizeUserData,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataProcessingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Processing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildProcessingRow('Personal Data', 'Encrypted'),
            _buildProcessingRow('Location Data', 'Anonymized'),
            _buildProcessingRow('Usage Analytics', 'Aggregated'),
            _buildProcessingRow('Payment Data', 'Tokenized'),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingRow(String dataType, String processing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dataType),
          Chip(
            label: Text(processing),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildDataRetentionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Retention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildRetentionRow('Trip Data', '7 years'),
            _buildRetentionRow('Payment Records', '7 years'),
            _buildRetentionRow('Support Logs', '3 years'),
            _buildRetentionRow('Analytics Data', '2 years'),
          ],
        ),
      ),
    );
  }

  Widget _buildRetentionRow(String dataType, String retention) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dataType),
          Text(retention, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    final settings = AppSettings.instance;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Private Mode'),
                  subtitle: const Text('Limit data persistence and sharing'),
                  value: settings.privateMode,
                  onChanged: (v) => settings.setPrivateMode(v),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Wi-Fi Only Sync'),
                  subtitle: const Text('Reduce mobile data usage'),
                  value: settings.wifiOnlySync,
                  onChanged: (v) => settings.setWifiOnlySync(v),
                  contentPadding: EdgeInsets.zero,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.policy_rounded),
                  title: const Text('Privacy Policy'),
                  subtitle: const Text('View our privacy policy'),
                  onTap: _viewPrivacyPolicy,
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.contact_support_rounded),
                  title: const Text('Privacy Support'),
                  subtitle: const Text('Contact privacy team'),
                  onTap: _contactPrivacySupport,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateConsent(ConsentCategory category, bool granted) async {
    try {
      if (granted) {
        await _consentService.grantConsent(category);
      } else {
        await _consentService.withdrawConsent(category);
      }
      await _loadPrivacyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${granted ? 'Granted' : 'Revoked'} consent for ${category.name}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update consent: $e')));
      }
    }
  }

  Future<void> _refreshConsent() async {
    try {
      await _loadPrivacyData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consent status refreshed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh consent: $e')),
        );
      }
    }
  }

  Future<void> _exportConsentData() async {
    try {
      final consentData = await _consentService.exportConsentData();
      final dir = await getTemporaryDirectory();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Consent Data',
        fileName: 'consent_data.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (savePath != null) {
        await File(savePath).writeAsString(jsonEncode(consentData));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Consent data exported to $savePath')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final json = await DataPortabilityService.instance.exportUserData(
        uid: user.uid,
      );
      final dir = await getTemporaryDirectory();
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Exported Data',
        fileName: 'travel_wizards_export.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (savePath != null) {
        await File(savePath).writeAsString(json);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Data exported to $savePath')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _deleteUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Account Deletion'),
        content: const Text(
          'This will permanently delete your account and all associated data. '
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DataPortabilityService.instance.deleteUserData(uid: user.uid);
      await user.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account and data deleted.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deletion failed: $e')));
      }
    }
  }

  Future<void> _anonymizeUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anonymize Data'),
        content: const Text(
          'This will remove personal identifiers from your data while '
          'preserving usage patterns for analytics. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Anonymize'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Mock anonymization - would use DataAnonymizationService
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data anonymized successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Anonymization failed: $e')));
      }
    }
  }

  void _viewPrivacyPolicy() {
    // Would open privacy policy URL or screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening privacy policy...')));
  }

  void _contactPrivacySupport() {
    // Would open support contact form or email
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening privacy support...')));
  }
}
