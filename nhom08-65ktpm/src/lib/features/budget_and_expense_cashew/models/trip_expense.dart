import 'package:cloud_firestore/cloud_firestore.dart';

class TripExpense {
  const TripExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.envelopeId,
    required this.category,
    required this.paymentSource,
    required this.paidBy,
    required this.paidByName,
    required this.splitType,
    required this.splitBetween,
    required this.splitDetails,
    required this.isOcrScanned,
    required this.spentAt,
    required this.createdBy,
    required this.createdAt,
    this.ocrDetectedAmount,
    this.ocrRawText,
    this.receiptImageUrl,
    this.receiptStoragePath,
    this.note,
  });

  final String id;
  final String title;
  final int amount;
  final String envelopeId;
  final String category;
  final String paymentSource;
  final String paidBy;
  final String paidByName;
  final String splitType;
  final List<String> splitBetween;
  final Map<String, int> splitDetails;
  final bool isOcrScanned;
  final int? ocrDetectedAmount;
  final String? ocrRawText;
  final String? receiptImageUrl;
  final String? receiptStoragePath;
  final DateTime spentAt;
  final String? note;
  final String createdBy;
  final DateTime createdAt;

  bool get isPersonalAdvance => paymentSource == 'personal_advance';

  factory TripExpense.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime dateFrom(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final rawDetails = data['splitDetails'];
    return TripExpense(
      id: id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.round() ?? 0,
      envelopeId: data['envelopeId'] as String? ?? '',
      category: data['category'] as String? ?? '',
      paymentSource: data['paymentSource'] as String? ?? 'personal_advance',
      paidBy: data['paidBy'] as String? ?? '',
      paidByName: data['paidByName'] as String? ?? '',
      splitType: data['splitType'] as String? ?? 'equal',
      splitBetween: (data['splitBetween'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      splitDetails: rawDetails is Map
          ? rawDetails.map(
              (key, value) => MapEntry(key.toString(), (value as num).round()),
            )
          : const {},
      isOcrScanned: data['isOcrScanned'] as bool? ?? false,
      ocrDetectedAmount: (data['ocrDetectedAmount'] as num?)?.round(),
      ocrRawText: data['ocrRawText'] as String?,
      receiptImageUrl: data['receiptImageUrl'] as String?,
      receiptStoragePath: data['receiptStoragePath'] as String?,
      spentAt: dateFrom(data['spentAt']),
      note: data['note'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: dateFrom(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'title': title,
    'amount': amount,
    'envelopeId': envelopeId,
    'category': category,
    'paymentSource': paymentSource,
    'paidBy': paidBy,
    'paidByName': paidByName,
    'splitType': splitType,
    'splitBetween': splitBetween,
    'splitDetails': splitDetails,
    'isOcrScanned': isOcrScanned,
    'ocrDetectedAmount': ocrDetectedAmount,
    'ocrRawText': ocrRawText,
    'receiptImageUrl': receiptImageUrl,
    'receiptStoragePath': receiptStoragePath,
    'spentAt': Timestamp.fromDate(spentAt),
    'note': note,
    'createdBy': createdBy,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
