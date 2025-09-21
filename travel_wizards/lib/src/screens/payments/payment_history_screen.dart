import 'package:flutter/material.dart';
import 'package:travel_wizards/src/common/ui/spacing.dart';
import 'package:travel_wizards/src/services/payments_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_wizards/src/services/error_handling_service.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: Insets.allSm,
            child: IconButton(
              tooltip: 'Add manual entry',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showAddManualDialog(context),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PaymentEntry>>(
            stream: PaymentsRepository.instance.watchPayments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              final items = snapshot.data ?? const <PaymentEntry>[];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: Insets.allMd,
                    child: Text('No payments yet.'),
                  ),
                );
              }
              return ListView.separated(
                padding: Insets.allMd,
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final p = items[index];
                  final amount = _formatAmount(p.amountCents, p.currency);
                  final isSuccess = p.status == 'success';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: isSuccess
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      child: Icon(
                        p.type == 'subscription'
                            ? Icons.star
                            : Icons.receipt_long,
                        color: isSuccess
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    title: Text(p.title),
                    subtitle: Text(
                      '${p.type} \u2022 ${p.platform ?? 'unknown'} \u2022 ${p.createdAt.toLocal().toString().split('.').first}'
                      '${(p.extra != null && (p.extra!['receiptUrl'] is String)) ? ' \u2022 receipt' : ''}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(amount, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          p.status,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isSuccess
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final urlStr = p.extra != null
                          ? p.extra!['receiptUrl'] as String?
                          : null;
                      if (urlStr != null && urlStr.isNotEmpty) {
                        final uri = Uri.tryParse(urlStr);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cannot open receipt URL'),
                              ),
                            );
                          }
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

String _formatAmount(int cents, String currency) {
  final major = (cents / 100.0);
  return '$currency ${major.toStringAsFixed(2)}';
}

class _ReceiptPicker extends StatefulWidget {
  const _ReceiptPicker({required this.onPicked});
  final void Function(String url) onPicked;
  @override
  State<_ReceiptPicker> createState() => _ReceiptPickerState();
}

class _ReceiptPickerState extends State<_ReceiptPicker> {
  String? _uploading;
  String? _url;

  Future<void> _pickAndUpload() async {
    if (!mounted) return;
    await _promptUploadOrUrl();
  }

  Future<void> _promptUploadOrUrl() async {
    final urlCtrl = TextEditingController();
    String? choice = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Attach receipt'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('paste'),
            child: const Text('Paste URL'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop('upload'),
            child: const Text('Upload file (PNG/JPG/PDF)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == null) return;
    if (choice == 'paste') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Paste receipt URL'),
          content: TextField(
            controller: urlCtrl,
            decoration: const InputDecoration(hintText: 'https://...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Attach'),
            ),
          ],
        ),
      );
      if (ok == true && urlCtrl.text.trim().isNotEmpty) {
        if (!mounted) return;
        setState(() => _url = urlCtrl.text.trim());
        widget.onPicked(_url!);
      }
      return;
    }
    if (choice == 'upload') {
      try {
        final res = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['png', 'jpg', 'jpeg', 'pdf'],
          withData: true,
        );
        if (res == null || res.files.isEmpty) return;
        final file = res.files.first;
        if (file.bytes == null) return;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        setState(() => _uploading = 'Uploading...');
        final ext = (file.extension ?? 'bin').toLowerCase();
        final path =
            'users/$uid/receipts/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final ref = FirebaseStorage.instance.ref().child(path);
        final meta = SettableMetadata(contentType: _guessContentType(ext));
        await ref.putData(file.bytes!, meta);
        final url = await ref.getDownloadURL();
        if (!mounted) return;
        setState(() {
          _url = url;
          _uploading = null;
        });
        widget.onPicked(url);
      } catch (e) {
        if (mounted) {
          ErrorHandlingService.instance.handlePaymentError(
            e,
            context: context,
            customMessage: 'Failed to upload receipt. Please try again.',
          );
        }
        setState(() => _uploading = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _uploading != null
                ? _uploading!
                : (_url == null ? 'No receipt attached' : 'Receipt attached'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        TextButton.icon(
          onPressed: _uploading == null ? _pickAndUpload : null,
          icon: const Icon(Icons.attach_file_rounded),
          label: const Text('Attach receipt'),
        ),
      ],
    );
  }
}

String _guessContentType(String ext) {
  switch (ext.toLowerCase()) {
    case 'png':
      return 'image/png';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    case 'pdf':
      return 'application/pdf';
    default:
      return 'application/octet-stream';
  }
}

Future<void> _showAddManualDialog(BuildContext context) async {
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController(text: 'Manual Expense');
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String currency = 'USD';
  bool saving = false;
  String? receiptUrl;

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    // Capture navigator before awaiting to avoid using BuildContext across async gaps.
    final navigator = Navigator.of(context);
    final amount = (double.tryParse(amountCtrl.text.trim()) ?? 0.0);
    final cents = (amount * 100).round();
    saving = true;
    try {
      await PaymentsRepository.instance.logPayment(
        type: 'manual',
        title: titleCtrl.text.trim().isEmpty
            ? 'Manual Expense'
            : titleCtrl.text.trim(),
        amountCents: cents,
        currency: currency,
        status: 'success',
        platform: 'manual',
        extra: {
          'note': noteCtrl.text.trim(),
          if (receiptUrl != null) 'receiptUrl': receiptUrl,
        },
      );
      if (navigator.canPop()) navigator.pop();
    } finally {
      saving = false;
    }
  }

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add Manual Entry'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextFormField(
              controller: amountCtrl,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                final val = double.tryParse(v ?? '');
                if (val == null || val <= 0) return 'Enter a valid amount';
                return null;
              },
            ),
            TextFormField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            DropdownButtonFormField<String>(
              initialValue: currency,
              decoration: const InputDecoration(labelText: 'Currency'),
              items: const [
                DropdownMenuItem(value: 'USD', child: Text('USD')),
                DropdownMenuItem(value: 'INR', child: Text('INR')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR')),
              ],
              onChanged: (v) => currency = v ?? 'USD',
            ),
            const SizedBox(height: 8),
            _ReceiptPicker(onPicked: (url) => receiptUrl = url),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : save,
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
