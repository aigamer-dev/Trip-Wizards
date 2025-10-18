import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pay/pay.dart';
import 'package:travel_wizards/src/shared/widgets/spacing.dart';
import 'package:travel_wizards/src/shared/services/payments_repository.dart';
import 'package:travel_wizards/src/shared/services/stripe_service.dart';

class TripPaymentSheet extends StatefulWidget {
  const TripPaymentSheet({
    super.key,
    required this.tripId,
    required this.amountCents,
    this.currency = 'USD',
    this.title,
    this.paymentType = 'trip',
    this.skipTripPaymentUpdate = false,
    this.extraLog,
    this.onPaymentSuccess,
  });
  final String tripId;
  final int amountCents;
  final String currency;
  final String? title;
  final String paymentType; // trip | booking_delta | subscription | other
  final bool skipTripPaymentUpdate;
  final Map<String, dynamic>? extraLog;
  final Future<void> Function()? onPaymentSuccess;

  @override
  State<TripPaymentSheet> createState() => _TripPaymentSheetState();
}

class _TripPaymentSheetState extends State<TripPaymentSheet> {
  bool _processing = false;
  PaymentConfiguration? _gpayConfig;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      PaymentConfiguration.fromAsset(
        'assets/payments/google_pay.json',
      ).then((c) => setState(() => _gpayConfig = c)).catchError((_) {});
    }
  }

  Future<void> _markPaid({
    required String platform,
    Map<String, dynamic>? extra,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final tripDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(widget.tripId);

    final mergedExtra = <String, dynamic>{}
      ..addAll(widget.extraLog ?? const {})
      ..addAll(extra ?? const {});

    await PaymentsRepository.instance.logPayment(
      type: widget.paymentType,
      title: 'Trip Payment',
      amountCents: widget.amountCents,
      currency: widget.currency,
      status: 'success',
      platform: platform,
      tripId: widget.tripId,
      extra: mergedExtra,
    );

    if (!widget.skipTripPaymentUpdate) {
      await tripDoc.set({
        'payment': {
          'status': 'paid',
          'amountCents': widget.amountCents,
          'currency': widget.currency,
          'paidAt': DateTime.now().toIso8601String(),
          'platform': platform,
        },
      }, SetOptions(merge: true));
    }

    if (widget.onPaymentSuccess != null) {
      await widget.onPaymentSuccess!.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText =
        '${widget.currency} ${(widget.amountCents / 100).toStringAsFixed(2)}';
    final items = <PaymentItem>[
      PaymentItem(
        label: 'Trip total',
        amount: (widget.amountCents / 100).toStringAsFixed(2),
        status: PaymentItemStatus.final_price,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: Insets.allMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.title ?? 'Checkout',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _processing
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Gaps.h8,
            Text(
              'Amount due: $amountText',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gaps.h16,
            if (Platform.isAndroid) ...[
              if (_gpayConfig == null)
                const Center(child: CircularProgressIndicator())
              else
                GooglePayButton(
                  paymentConfiguration: _gpayConfig!,
                  paymentItems: items,
                  type: GooglePayButtonType.pay,
                  width: double.infinity,
                  onPaymentResult: (result) async {
                    if (_processing) {
                      return;
                    }
                    setState(() => _processing = true);
                    try {
                      await _markPaid(
                        platform: 'google_pay',
                        extra: {'result': result},
                      );
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Payment error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _processing = false);
                      }
                    }
                  },
                  loadingIndicator: const CircularProgressIndicator(),
                ),
              Gaps.h8,
              OutlinedButton.icon(
                onPressed: _processing
                    ? null
                    : () async {
                        setState(() => _processing = true);
                        try {
                          final ok = await StripeService.instance
                              .payWithPaymentSheet(
                                amountCents: widget.amountCents,
                                currency: widget.currency,
                                description: 'Trip ${widget.tripId}',
                              );
                          if (ok) {
                            await _markPaid(platform: 'stripe');
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Stripe not configured or payment canceled',
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Stripe error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _processing = false);
                          }
                        }
                      },
                icon: const Icon(Icons.credit_card_rounded),
                label: const Text('Pay with Card (Stripe)'),
              ),
              Text(
                'Test environment: use a device signed into Play with test cards.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'Google Pay available on Android; using simulated payment here.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Gaps.h8,
              FilledButton.icon(
                onPressed: _processing
                    ? null
                    : () async {
                        setState(() => _processing = true);
                        await Future<void>.delayed(
                          const Duration(milliseconds: 600),
                        );
                        await _markPaid(platform: 'simulated');
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                        if (mounted) {
                          setState(() => _processing = false);
                        }
                      },
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Simulate Payment'),
              ),
              Gaps.h8,
              OutlinedButton.icon(
                onPressed: _processing
                    ? null
                    : () async {
                        setState(() => _processing = true);
                        try {
                          final ok = await StripeService.instance
                              .payWithPaymentSheet(
                                amountCents: widget.amountCents,
                                currency: widget.currency,
                                description: 'Trip ${widget.tripId}',
                              );
                          if (ok) {
                            await _markPaid(platform: 'stripe');
                            if (context.mounted) {
                              Navigator.of(context).pop(true);
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Stripe not configured or payment canceled',
                                  ),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Stripe error: $e')),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _processing = false);
                          }
                        }
                      },
                icon: const Icon(Icons.credit_card_rounded),
                label: const Text('Pay with Card (Stripe)'),
              ),
            ],
            Gaps.h16,
          ],
        ),
      ),
    );
  }
}
