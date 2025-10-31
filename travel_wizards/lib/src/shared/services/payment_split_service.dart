import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Expense {
  final String id;
  final String tripId;
  final String description;
  final double amount;
  final String paidBy;
  final List<String> splitAmong;
  final DateTime timestamp;
  final Map<String, double> individualShares;

  Expense({
    required this.id,
    required this.tripId,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.splitAmong,
    required this.timestamp,
    required this.individualShares,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paidBy: data['paidBy'] ?? '',
      splitAmong: List<String>.from(data['splitAmong'] ?? []),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      individualShares: Map<String, double>.from(
        data['individualShares'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splitAmong': splitAmong,
      'timestamp': FieldValue.serverTimestamp(),
      'individualShares': individualShares,
    };
  }
}

class PaymentSplitService {
  PaymentSplitService._();
  static final PaymentSplitService instance = PaymentSplitService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense({
    required String tripId,
    required String description,
    required double amount,
    required List<String> splitAmong,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sharePerPerson = amount / splitAmong.length;
    final individualShares = <String, double>{};
    for (final person in splitAmong) {
      individualShares[person] = sharePerPerson;
    }

    final expense = Expense(
      id: '',
      tripId: tripId,
      description: description,
      amount: amount,
      paidBy: user.uid,
      splitAmong: splitAmong,
      timestamp: DateTime.now(),
      individualShares: individualShares,
    );

    await _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .add(expense.toMap());
  }

  Stream<List<Expense>> getExpenses(String tripId) {
    return _firestore
        .collection('trips')
        .doc(tripId)
        .collection('expenses')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList(),
        );
  }

  Map<String, double> calculateBalances(
    List<Expense> expenses,
    List<String> members,
  ) {
    final balances = <String, double>{};

    for (final member in members) {
      balances[member] = 0.0;
    }

    for (final expense in expenses) {
      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + expense.amount;

      for (final entry in expense.individualShares.entries) {
        balances[entry.key] = (balances[entry.key] ?? 0) - entry.value;
      }
    }

    return balances;
  }

  List<PaymentSettlement> suggestSettlements(Map<String, double> balances) {
    final settlements = <PaymentSettlement>[];
    final debtors = <String, double>{};
    final creditors = <String, double>{};

    for (final entry in balances.entries) {
      if (entry.value < 0) {
        debtors[entry.key] = -entry.value;
      } else if (entry.value > 0) {
        creditors[entry.key] = entry.value;
      }
    }

    final debtorList = debtors.entries.toList();
    final creditorList = creditors.entries.toList();

    int i = 0, j = 0;
    while (i < debtorList.length && j < creditorList.length) {
      final debtor = debtorList[i];
      final creditor = creditorList[j];

      final amount = debtor.value < creditor.value
          ? debtor.value
          : creditor.value;

      settlements.add(
        PaymentSettlement(from: debtor.key, to: creditor.key, amount: amount),
      );

      debtorList[i] = MapEntry(debtor.key, debtor.value - amount);
      creditorList[j] = MapEntry(creditor.key, creditor.value - amount);

      if (debtorList[i].value == 0) i++;
      if (creditorList[j].value == 0) j++;
    }

    return settlements;
  }
}

class PaymentSettlement {
  final String from;
  final String to;
  final double amount;

  PaymentSettlement({
    required this.from,
    required this.to,
    required this.amount,
  });
}
