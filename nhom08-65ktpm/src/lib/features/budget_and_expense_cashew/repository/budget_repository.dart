import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/mock_trip_data.dart';
import '../models/budget_envelope.dart';
import '../models/trip_expense.dart';

abstract interface class BudgetRepository {
  Stream<List<BudgetEnvelope>> watchEnvelopes(
    String tripId, {
    required int targetBudget,
    required bool initializeDefaults,
  });

  Stream<List<TripExpense>> watchExpenses(
    String tripId, {
    required int targetBudget,
  });

  Future<void> updateEnvelopeBudget({
    required String tripId,
    required String envelopeId,
    required int allocatedAmount,
  });

  Future<TripExpense> addExpense({
    required String tripId,
    required TripExpense expense,
  });
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  if (Firebase.apps.isEmpty) {
    final repository = InMemoryBudgetRepository();
    ref.onDispose(repository.dispose);
    return repository;
  }
  return FirestoreBudgetRepository();
});

class FirestoreBudgetRepository implements BudgetRepository {
  FirestoreBudgetRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _envelopes(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('budget_envelopes');

  CollectionReference<Map<String, dynamic>> _expenses(String tripId) =>
      _firestore.collection('trips').doc(tripId).collection('expenses');

  @override
  Stream<List<BudgetEnvelope>> watchEnvelopes(
    String tripId, {
    required int targetBudget,
    required bool initializeDefaults,
  }) async* {
    if (initializeDefaults) {
      await _ensureDefaultEnvelopes(tripId, targetBudget);
    }
    yield* _envelopes(tripId).snapshots().map((snapshot) {
      final result = snapshot.docs
          .map((doc) => BudgetEnvelope.fromFirestore(doc.id, doc.data()))
          .toList();
      result.sort(
        (a, b) => _categoryIndex(a.id).compareTo(_categoryIndex(b.id)),
      );
      return result;
    });
  }

  @override
  Stream<List<TripExpense>> watchExpenses(
    String tripId, {
    required int targetBudget,
  }) {
    return _expenses(tripId)
        .orderBy('spentAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TripExpense.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> _ensureDefaultEnvelopes(String tripId, int targetBudget) async {
    final collection = _envelopes(tripId);
    final references = BudgetEnvelope.defaults
        .map((item) => collection.doc(item.id))
        .toList();
    await _firestore.runTransaction((transaction) async {
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final reference in references) {
        snapshots.add(await transaction.get(reference));
      }
      final existingIds = {
        for (var index = 0; index < snapshots.length; index++)
          if (snapshots[index].exists) references[index].id,
      };

      var allocated = 0;
      for (final item in BudgetEnvelope.defaults) {
        final amount = item == BudgetEnvelope.defaults.last
            ? targetBudget - allocated
            : targetBudget * item.weight ~/ 100;
        allocated += amount;
        if (existingIds.contains(item.id)) continue;
        transaction.set(collection.doc(item.id), {
          'id': item.id,
          'category': item.id,
          'name': item.name,
          'iconCode': item.iconCode,
          'colorHex': item.colorHex,
          'allocatedAmount': amount,
          'plannedFromItinerary': 0,
          'spentAmount': 0,
          'updatedAt': Timestamp.now(),
        });
      }
    });
  }

  @override
  Future<void> updateEnvelopeBudget({
    required String tripId,
    required String envelopeId,
    required int allocatedAmount,
  }) async {
    if (allocatedAmount < 0) {
      throw ArgumentError.value(allocatedAmount, 'allocatedAmount');
    }
    await _envelopes(tripId).doc(envelopeId).update({
      'allocatedAmount': allocatedAmount,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<TripExpense> addExpense({
    required String tripId,
    required TripExpense expense,
  }) async {
    if (expense.amount <= 0) {
      throw ArgumentError.value(expense.amount, 'amount');
    }
    if (expense.splitDetails.values.fold<int>(0, (a, b) => a + b) !=
        expense.amount) {
      throw ArgumentError('Expense split must equal its amount.');
    }

    final expenseRef = _expenses(tripId).doc();
    final envelopeRef = _envelopes(tripId).doc(expense.envelopeId);
    final tripRef = _firestore.collection('trips').doc(tripId);
    final saved = TripExpense(
      id: expenseRef.id,
      title: expense.title,
      amount: expense.amount,
      envelopeId: expense.envelopeId,
      category: expense.category,
      paymentSource: expense.paymentSource,
      paidBy: expense.paidBy,
      paidByName: expense.paidByName,
      splitType: expense.splitType,
      splitBetween: expense.splitBetween,
      splitDetails: expense.splitDetails,
      isOcrScanned: expense.isOcrScanned,
      ocrDetectedAmount: expense.ocrDetectedAmount,
      ocrRawText: expense.ocrRawText,
      receiptImageUrl: expense.receiptImageUrl,
      receiptStoragePath: expense.receiptStoragePath,
      spentAt: expense.spentAt,
      note: expense.note,
      createdBy: expense.createdBy,
      createdAt: DateTime.now(),
    );

    await _firestore.runTransaction((transaction) async {
      final envelope = await transaction.get(envelopeRef);
      if (!envelope.exists) {
        throw StateError('Không tìm thấy hũ ngân sách đã chọn.');
      }
      transaction.set(expenseRef, saved.toFirestore());
      transaction.update(envelopeRef, {
        'spentAmount': FieldValue.increment(saved.amount),
        'updatedAt': Timestamp.now(),
      });
      transaction.update(tripRef, {
        'totalSpentAmount': FieldValue.increment(saved.amount),
        'updatedAt': Timestamp.now(),
      });
    });
    return saved;
  }

  int _categoryIndex(String id) {
    final index = BudgetEnvelope.defaults.indexWhere((item) => item.id == id);
    return index == -1 ? BudgetEnvelope.defaults.length : index;
  }
}

class InMemoryBudgetRepository implements BudgetRepository {
  final Map<String, List<BudgetEnvelope>> _envelopesByTrip = {};
  final Map<String, List<TripExpense>> _expensesByTrip = {};
  final StreamController<String> _changes =
      StreamController<String>.broadcast();
  var _nextExpenseId = 0;

  @override
  Stream<List<BudgetEnvelope>> watchEnvelopes(
    String tripId, {
    required int targetBudget,
    required bool initializeDefaults,
  }) async* {
    _seed(tripId, targetBudget);
    yield List.unmodifiable(_envelopesByTrip[tripId]!);
    await for (final changedTripId in _changes.stream) {
      if (changedTripId == tripId) {
        yield List.unmodifiable(_envelopesByTrip[tripId]!);
      }
    }
  }

  @override
  Stream<List<TripExpense>> watchExpenses(
    String tripId, {
    required int targetBudget,
  }) async* {
    _seed(tripId, targetBudget);
    yield List.unmodifiable(_expensesByTrip[tripId]!);
    await for (final changedTripId in _changes.stream) {
      if (changedTripId == tripId) {
        yield List.unmodifiable(_expensesByTrip[tripId]!);
      }
    }
  }

  void _seed(String tripId, int targetBudget) {
    if (_envelopesByTrip.containsKey(tripId)) return;
    if (tripId != 'demo-trip') {
      _envelopesByTrip[tripId] = _defaultEnvelopes(targetBudget);
      _expensesByTrip[tripId] = [];
      return;
    }

    final mockEnvelopes = <BudgetEnvelope>[];
    for (final item in BudgetEnvelope.defaults) {
      final mockCategory = item.name == 'Vé' ? 'Vé tham quan' : item.name;
      final mock = MockTripData.envelopes.where(
        (e) => e.category == mockCategory,
      );
      final match = mock.isEmpty ? null : mock.first;
      mockEnvelopes.add(
        BudgetEnvelope(
          id: item.id,
          category: item.id,
          name: item.name,
          iconCode: item.iconCode,
          colorHex: item.colorHex,
          allocatedAmount: match?.planned ?? 0,
          plannedFromItinerary: match?.planned ?? 0,
          spentAmount: match?.spent ?? 0,
        ),
      );
    }
    _envelopesByTrip[tripId] = mockEnvelopes;

    final mockExpenses = <TripExpense>[];
    for (var index = 0; index < MockTripData.expenses.length; index++) {
      final mock = MockTripData.expenses[index];
      final payer = MockTripData.members.firstWhere(
        (member) => member.name == mock.payerName,
      );
      final payerId = _demoMemberId(payer.name);
      final amountPerMember = mock.amount ~/ MockTripData.members.length;
      var remainder = mock.amount % MockTripData.members.length;
      final details = <String, int>{};
      for (final member in MockTripData.members) {
        details[_demoMemberId(member.name)] =
            amountPerMember + (remainder > 0 ? 1 : 0);
        if (remainder > 0) remainder--;
      }
      final envelope = mockEnvelopes.firstWhere(
        (item) => item.name == mock.category,
      );
      mockExpenses.add(
        TripExpense(
          id: mock.id,
          title: mock.title,
          amount: mock.amount,
          envelopeId: envelope.id,
          category: envelope.category,
          paymentSource: 'personal_advance',
          paidBy: payerId,
          paidByName: payer.name,
          splitType: 'equal',
          splitBetween: details.keys.toList(),
          splitDetails: details,
          isOcrScanned: false,
          spentAt: DateTime(2026, 11, 15 + index),
          createdBy: payerId,
          createdAt: DateTime(2026, 11, 15 + index),
        ),
      );
    }
    _expensesByTrip[tripId] = mockExpenses;
  }

  String _demoMemberId(String name) {
    switch (name) {
      case 'Đỗ Đình An':
        return 'demo-host-an';
      case 'Nguyễn Xuân Bình':
        return 'demo-member-binh';
      case 'Hồ Thế Dũng':
        return 'demo-member-dung';
      case 'Đỗ Tùng Khánh':
        return 'demo-member-khanh';
      default:
        return name;
    }
  }

  List<BudgetEnvelope> _defaultEnvelopes(int targetBudget) {
    var allocated = 0;
    return BudgetEnvelope.defaults.map((item) {
      final amount = item == BudgetEnvelope.defaults.last
          ? targetBudget - allocated
          : targetBudget * item.weight ~/ 100;
      allocated += amount;
      return BudgetEnvelope(
        id: item.id,
        category: item.id,
        name: item.name,
        iconCode: item.iconCode,
        colorHex: item.colorHex,
        allocatedAmount: amount,
        plannedFromItinerary: 0,
        spentAmount: 0,
      );
    }).toList();
  }

  @override
  Future<void> updateEnvelopeBudget({
    required String tripId,
    required String envelopeId,
    required int allocatedAmount,
  }) async {
    if (allocatedAmount < 0) {
      throw ArgumentError.value(allocatedAmount, 'allocatedAmount');
    }
    final envelopes =
        _envelopesByTrip[tripId] ??
        _defaultEnvelopes(MockTripData.totalTargetFund);
    final index = envelopes.indexWhere((item) => item.id == envelopeId);
    if (index == -1) throw StateError('Không tìm thấy hũ ngân sách.');
    final old = envelopes[index];
    envelopes[index] = BudgetEnvelope(
      id: old.id,
      category: old.category,
      name: old.name,
      iconCode: old.iconCode,
      colorHex: old.colorHex,
      allocatedAmount: allocatedAmount,
      plannedFromItinerary: old.plannedFromItinerary,
      spentAmount: old.spentAmount,
    );
    _envelopesByTrip[tripId] = envelopes;
    _changes.add(tripId);
  }

  @override
  Future<TripExpense> addExpense({
    required String tripId,
    required TripExpense expense,
  }) async {
    if (expense.amount <= 0) {
      throw ArgumentError.value(expense.amount, 'amount');
    }
    if (expense.splitDetails.values.fold<int>(0, (a, b) => a + b) !=
        expense.amount) {
      throw ArgumentError('Expense split must equal its amount.');
    }
    _seed(tripId, MockTripData.totalTargetFund);
    final envelopes = _envelopesByTrip[tripId]!;
    final index = envelopes.indexWhere((item) => item.id == expense.envelopeId);
    if (index == -1) throw StateError('Không tìm thấy hũ ngân sách.');
    final old = envelopes[index];
    envelopes[index] = BudgetEnvelope(
      id: old.id,
      category: old.category,
      name: old.name,
      iconCode: old.iconCode,
      colorHex: old.colorHex,
      allocatedAmount: old.allocatedAmount,
      plannedFromItinerary: old.plannedFromItinerary,
      spentAmount: old.spentAmount + expense.amount,
    );
    final saved = TripExpense(
      id: 'expense-${DateTime.now().microsecondsSinceEpoch}-${_nextExpenseId++}',
      title: expense.title,
      amount: expense.amount,
      envelopeId: expense.envelopeId,
      category: expense.category,
      paymentSource: expense.paymentSource,
      paidBy: expense.paidBy,
      paidByName: expense.paidByName,
      splitType: expense.splitType,
      splitBetween: expense.splitBetween,
      splitDetails: expense.splitDetails,
      isOcrScanned: expense.isOcrScanned,
      ocrDetectedAmount: expense.ocrDetectedAmount,
      ocrRawText: expense.ocrRawText,
      receiptImageUrl: expense.receiptImageUrl,
      receiptStoragePath: expense.receiptStoragePath,
      spentAt: expense.spentAt,
      note: expense.note,
      createdBy: expense.createdBy,
      createdAt: DateTime.now(),
    );
    _expensesByTrip.putIfAbsent(tripId, () => []).insert(0, saved);
    _changes.add(tripId);
    return saved;
  }

  void dispose() => _changes.close();
}
