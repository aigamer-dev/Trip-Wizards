import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:travel_wizards/src/shared/services/payments_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:travel_wizards/src/shared/services/error_handling_service.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_page_scaffold.dart';
import 'package:travel_wizards/src/shared/widgets/layout/modern_section.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ModernPageScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddManualDialog(context),
        tooltip: 'Add Manual Entry',
        child: const Icon(Symbols.add),
      ),
      sections: [
        ModernSection(
          title: 'Transaction History',
          child: StreamBuilder<List<PaymentEntry>>(
            stream: PaymentsRepository.instance.watchPayments(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _EmptyPayments(
                  icon: Symbols.error,
                  message: 'Error loading payments: ${snapshot.error}',
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const _EmptyPayments(
                  icon: Symbols.receipt_long,
                  message: 'No payment history found.',
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _PaymentCard(payment: items[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final PaymentEntry payment;

  String _formatAmount(int cents, String currency) {
    final format = NumberFormat.simpleCurrency(
      name: currency,
      decimalDigits: 2,
    );
    return format.format(cents / 100.0);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'subscription':
        return Symbols.star;
      case 'booking':
        return Symbols.airplane_ticket;
      case 'manual':
        return Symbols.edit;
      default:
        return Symbols.receipt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSuccess = payment.status == 'success';
    final amount = _formatAmount(payment.amountCents, payment.currency);
    final date = DateFormat.yMMMd().add_jm().format(
      payment.createdAt.toLocal(),
    );

    final receiptUrl = payment.extra?['receiptUrl'] as String?;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: (receiptUrl != null && receiptUrl.isNotEmpty)
            ? () async {
                final uri = Uri.tryParse(receiptUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot open receipt URL')),
                  );
                }
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isSuccess
                    ? colorScheme.primary
                    : colorScheme.error,
                child: Icon(
                  _getIconForType(payment.type),
                  color: isSuccess
                      ? colorScheme.onPrimary
                      : colorScheme.onError,
                ),
              ),
              Gaps.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gaps.h8,
                    Text(
                      '${payment.platform ?? 'unknown'} • $date',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.w16,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSuccess
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                  ),
                  Gaps.h8,
                  Row(
                    children: [
                      Text(
                        payment.status,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSuccess
                              ? colorScheme.secondary
                              : colorScheme.error,
                        ),
                      ),
                      if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
                        Gaps.w8,
                        Icon(
                          Symbols.open_in_new,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyPayments extends StatelessWidget {
  const _EmptyPayments({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.secondary.withAlpha((0.7 * 255).toInt()),
            ),
            Gaps.h24,
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddManualEntryDialog extends StatefulWidget {
  const _AddManualEntryDialog();

  @override
  State<_AddManualEntryDialog> createState() => _AddManualEntryDialogState();
}

class _AddManualEntryDialogState extends State<_AddManualEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController(text: 'Manual Expense');
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _currency = 'USD';
  bool _isSaving = false;
  String? _receiptUrl;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final amount = (double.tryParse(_amountCtrl.text.trim()) ?? 0.0);
      final cents = (amount * 100).round();

      await PaymentsRepository.instance.logPayment(
        type: 'manual',
        title: _titleCtrl.text.trim().isEmpty
            ? 'Manual Expense'
            : _titleCtrl.text.trim(),
        amountCents: cents,
        currency: _currency,
        status: 'success',
        platform: 'manual',
        extra: {
          'note': _noteCtrl.text.trim(),
          if (_receiptUrl != null) 'receiptUrl': _receiptUrl,
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlingService.instance.handlePaymentError(
          e,
          context: context,
          customMessage: 'Failed to save manual entry.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Manual Entry'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextFormField(
                controller: _amountCtrl,
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
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: const [
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'INR', child: Text('INR')),
                  DropdownMenuItem(value: 'EUR', child: Text('EUR')),
                ],
                onChanged: (v) => setState(() => _currency = v ?? 'USD'),
              ),
              const SizedBox(height: 8),
              _ReceiptPicker(onPicked: (url) => _receiptUrl = url),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

Future<void> _showAddManualDialog(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (_) => const _AddManualEntryDialog(),
  );
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
