import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Get the expenses collection reference for a trip
  /// Expenses are stored in users/{ownerId}/trips/{tripId}/expenses
  CollectionReference<Map<String, dynamic>> _getExpensesCollection(
    String tripId,
    String ownerId,
  ) {
    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('trips')
        .doc(tripId)
        .collection('expenses');
  }

  /// Get trip owner ID from current user's trips
  Future<String?> _getTripOwnerId(String tripId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Check if trip belongs to current user
    final userTripDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('trips')
        .doc(tripId)
        .get();

    if (userTripDoc.exists) {
      return user.uid;
    }

    // For now, return current user as fallback
    return user.uid;
  }

  Future<void> addExpense({
    required String tripId,
    required String description,
    required double amount,
    required List<String> splitAmong,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ownerId = await _getTripOwnerId(tripId);
    if (ownerId == null) return;

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

    await _getExpensesCollection(tripId, ownerId).add(expense.toMap());
  }

  Stream<List<Expense>> getExpenses(String tripId) async* {
    final ownerId = await _getTripOwnerId(tripId);
    if (ownerId == null) {
      yield [];
      return;
    }

    yield* _getExpensesCollection(tripId, ownerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updateExpense({
    required String tripId,
    required String expenseId,
    required String description,
    required double amount,
    required List<String> splitAmong,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ownerId = await _getTripOwnerId(tripId);
    if (ownerId == null) return;

    final sharePerPerson = amount / splitAmong.length;
    final individualShares = <String, double>{};
    for (final person in splitAmong) {
      individualShares[person] = sharePerPerson;
    }

    await _getExpensesCollection(tripId, ownerId).doc(expenseId).update({
      'description': description,
      'amount': amount,
      'splitAmong': splitAmong,
      'individualShares': individualShares,
    });
  }

  Future<void> deleteExpense({
    required String tripId,
    required String expenseId,
  }) async {
    final ownerId = await _getTripOwnerId(tripId);
    if (ownerId == null) return;

    await _getExpensesCollection(tripId, ownerId).doc(expenseId).delete();
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
