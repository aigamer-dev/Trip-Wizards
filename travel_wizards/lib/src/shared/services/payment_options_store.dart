import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PaymentOption {
  final String id;
  final String type; // e.g. 'card', 'google_pay', 'upi', 'paypal', 'other'
  final String label; // user-friendly label
  final String? last4; // optional last4 for cards
  final String? brand; // optional brand for cards
  final int addedAtMillis;

  PaymentOption({
    required this.id,
    required this.type,
    required this.label,
    this.last4,
    this.brand,
    required this.addedAtMillis,
  });

  PaymentOption copyWith({String? label, String? last4, String? brand}) {
    return PaymentOption(
      id: id,
      type: type,
      label: label ?? this.label,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      addedAtMillis: addedAtMillis,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'label': label,
    'last4': last4,
    'brand': brand,
    'addedAtMillis': addedAtMillis,
  };

  static PaymentOption fromMap(Map map) => PaymentOption(
    id: map['id'] as String,
    type: map['type'] as String,
    label: map['label'] as String,
    last4: map['last4'] as String?,
    brand: map['brand'] as String?,
    addedAtMillis: (map['addedAtMillis'] as num).toInt(),
  );
}

class PaymentOptionsStore extends ChangeNotifier {
  static final PaymentOptionsStore instance = PaymentOptionsStore._();
  PaymentOptionsStore._();

  static const String _boxName = 'payment_options';
  Box? _box;
  bool _initialized = false;

  List<PaymentOption> _options = [];
  List<PaymentOption> get options => List.unmodifiable(_options);
  bool get isReady => _initialized;

  Future<void> _openBox() async {
    _box ??= await Hive.openBox(_boxName);
  }

  Future<void> ensureReady() async {
    if (_initialized) return;
    await _openBox();
    _loadFromBox();
    _initialized = true;
    notifyListeners();
  }

  void _loadFromBox() {
    final b = _box!;
    _options =
        b.values.whereType<Map>().map((e) => PaymentOption.fromMap(e)).toList()
          ..sort((a, b) => b.addedAtMillis.compareTo(a.addedAtMillis));
  }

  String _genId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = Random().nextInt(0xFFFF);
    return 'po_${ts}_$r';
  }

  Future<PaymentOption> addOption({
    required String type,
    required String label,
    String? last4,
    String? brand,
  }) async {
    await ensureReady();
    final item = PaymentOption(
      id: _genId(),
      type: type,
      label: label,
      last4: last4,
      brand: brand,
      addedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _box!.put(item.id, item.toMap());
    _loadFromBox();
    notifyListeners();
    return item;
  }

  Future<void> removeOption(String id) async {
    await ensureReady();
    await _box!.delete(id);
    _loadFromBox();
    notifyListeners();
  }

  Future<void> updateLabel(String id, String newLabel) async {
    await ensureReady();
    final existing = _box!.get(id);
    if (existing is Map) {
      existing['label'] = newLabel;
      await _box!.put(id, existing);
      _loadFromBox();
      notifyListeners();
    }
  }
}
