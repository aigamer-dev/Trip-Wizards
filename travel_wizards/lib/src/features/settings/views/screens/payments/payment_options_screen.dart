import 'package:flutter/material.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/payment_options_store.dart';

class PaymentOptionsScreen extends StatefulWidget {
  const PaymentOptionsScreen({super.key});

  @override
  State<PaymentOptionsScreen> createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  final store = PaymentOptionsStore.instance;

  @override
  void initState() {
    super.initState();
    store.ensureReady();
  }

  void _showAddDialog() {
    final typeCtl = ValueNotifier<String>('card');
    final labelCtl = TextEditingController();
    // legacy fields removed in favor of type-specific inputs
    final upiCtl = TextEditingController();
    final cardNumberCtl = TextEditingController();
    final cardExpiryCtl = TextEditingController();
    final cardCvvCtl = TextEditingController();
    final cardNameCtl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Padding(
            padding: Insets.allMd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add payment option',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Gaps.h8,
                ValueListenableBuilder(
                  valueListenable: typeCtl,
                  builder: (context, type, _) =>
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        items: const [
                          DropdownMenuItem(value: 'card', child: Text('Card')),
                          DropdownMenuItem(
                            value: 'google_pay',
                            child: Text('Google Pay'),
                          ),
                          DropdownMenuItem(value: 'upi', child: Text('UPI')),
                          DropdownMenuItem(
                            value: 'paypal',
                            child: Text('PayPal'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (v) => typeCtl.value = v ?? 'card',
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                ),
                ValueListenableBuilder(
                  valueListenable: typeCtl,
                  builder: (context, type, _) {
                    switch (type) {
                      case 'upi':
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: labelCtl,
                              decoration: const InputDecoration(
                                labelText: 'Label',
                                hintText: 'e.g., Personal UPI',
                              ),
                            ),
                            TextField(
                              controller: upiCtl,
                              decoration: const InputDecoration(
                                labelText: 'UPI ID',
                                hintText: 'name@bank',
                              ),
                            ),
                          ],
                        );
                      case 'card':
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: labelCtl,
                              decoration: const InputDecoration(
                                labelText: 'Label',
                                hintText: 'e.g., Personal Visa',
                              ),
                            ),
                            TextField(
                              controller: cardNumberCtl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Card number',
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: cardExpiryCtl,
                                    keyboardType: TextInputType.datetime,
                                    decoration: const InputDecoration(
                                      labelText: 'Expiry (MM/YY)',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: cardCvvCtl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'CVV',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            TextField(
                              controller: cardNameCtl,
                              decoration: const InputDecoration(
                                labelText: 'Name on card',
                              ),
                            ),
                          ],
                        );
                      case 'google_pay':
                      case 'paypal':
                      case 'other':
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: labelCtl,
                              decoration: const InputDecoration(
                                labelText: 'Label',
                                hintText: 'e.g., Google Pay',
                              ),
                            ),
                            Text(
                              'Net Banking: coming soon',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      if (labelCtl.text.trim().isEmpty) return;
                      // Persist minimal details depending on type
                      String? last4;
                      String? brand;
                      if (typeCtl.value == 'card') {
                        final num = cardNumberCtl.text.replaceAll(' ', '');
                        if (num.length >= 4) {
                          last4 = num.substring(num.length - 4);
                        }
                        brand = 'Card';
                      } else if (typeCtl.value == 'upi') {
                        brand = upiCtl.text.trim();
                      }
                      await store.addOption(
                        type: typeCtl.value,
                        label: labelCtl.text.trim(),
                        brand: (brand != null && brand.isNotEmpty)
                            ? brand
                            : null,
                        last4: last4,
                      );
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final items = store.options;
        return ListView(
          padding: Insets.allMd,
          children: [
            Card.outlined(
              child: Padding(
                padding: Insets.allMd,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_rounded, color: theme.colorScheme.primary),
                    Gaps.w16,
                    Expanded(
                      child: Text(
                        'Your saved payment options are stored only on this device and are not synced to the cloud for your security and privacy.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Gaps.h8,
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet_outlined, size: 48),
                    Gaps.h8,
                    Text(
                      'No payment options yet',
                      style: theme.textTheme.titleMedium,
                    ),
                    Gaps.h8,
                    Text(
                      'Add a card, UPI, Google Pay, or other method to speed up checkout.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Gaps.h16,
                    FilledButton.icon(
                      onPressed: _showAddDialog,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add payment option'),
                    ),
                  ],
                ),
              )
            else
              ...items.map(
                (p) => Card(
                  child: ListTile(
                    leading: Icon(
                      p.type == 'card'
                          ? Icons.credit_card_rounded
                          : p.type == 'google_pay'
                          ? Icons.payments_rounded
                          : p.type == 'upi'
                          ? Icons.qr_code_2_rounded
                          : p.type == 'paypal'
                          ? Icons.account_balance_wallet_rounded
                          : Icons.payment_rounded,
                    ),
                    title: Text(p.label),
                    subtitle: Text(
                      [
                        if (p.brand != null) p.brand!,
                        if (p.last4 != null) '•••• ${p.last4}',
                      ].join(' · '),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      tooltip: 'Remove',
                      onPressed: () async {
                        await store.removeOption(p.id);
                      },
                    ),
                  ),
                ),
              ),
            if (items.isNotEmpty) ...[
              Gaps.h16,
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add new'),
                ),
              ),
            ],
            Gaps.h24,
          ],
        );
      },
    );
  }
}
