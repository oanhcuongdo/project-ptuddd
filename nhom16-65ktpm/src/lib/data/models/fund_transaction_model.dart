import 'dart:convert';
import 'package:intl/intl.dart';

enum TransactionType {
  thu, // Gây quỹ từ thử thách hoàn thành hoặc nhà tài trợ
  chi, // Giải ngân từ thiện
}

/// Model cho bảng `fund_transactions`
class FundTransactionModel {
  final String id;
  final String? proofId; // null nếu là khoản chi hoặc thu từ nhà tài trợ trực tiếp
  final TransactionType type;
  final double amount;
  final String title;
  final String category; // vd: 'Kỷ luật', 'Gia sư', 'Giáo dục', 'Tài trợ mở quỹ'...
  final String? proofImagePath; // Ủy nhiệm chi, sao kê chuyển khoản hoặc ảnh minh chứng
  final String note;
  final String recipientOrSponsor; // Người nhận (nếu chi) hoặc Nhà hảo tâm (nếu thu)
  final DateTime createdAt;

  const FundTransactionModel({
    required this.id,
    this.proofId,
    required this.type,
    required this.amount,
    required this.title,
    required this.category,
    this.proofImagePath,
    this.note = '',
    required this.recipientOrSponsor,
    required this.createdAt,
  });

  bool get isIncome => type == TransactionType.thu;
  bool get isExpense => type == TransactionType.chi;

  String get typeDisplay => isIncome ? 'Thu' : 'Chi';

  String get formattedAmount {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final prefix = isIncome ? '+' : '-';
    return '$prefix${formatter.format(amount)}';
  }

  String get formattedCreatedAt {
    final formatter = DateFormat('HH:mm - dd/MM/yyyy');
    return formatter.format(createdAt);
  }

  /// Chuyển đối tượng thành Map để lưu vào SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proofId': proofId,
      'type': type.name,
      'amount': amount,
      'title': title,
      'category': category,
      'proofImagePath': proofImagePath,
      'note': note,
      'recipientOrSponsor': recipientOrSponsor,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Khởi tạo đối tượng từ Map lấy từ SQLite
  factory FundTransactionModel.fromMap(Map<String, dynamic> map) {
    return FundTransactionModel(
      id: map['id'] as String,
      proofId: map['proofId'] as String?,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.thu,
      ),
      amount: (map['amount'] as num).toDouble(),
      title: map['title'] as String,
      category: map['category'] as String? ?? 'Khác',
      proofImagePath: map['proofImagePath'] as String?,
      note: map['note'] as String? ?? '',
      recipientOrSponsor: map['recipientOrSponsor'] as String? ?? 'Quỹ chung',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// JSON Serialization
  Map<String, dynamic> toJson() => toMap();

  factory FundTransactionModel.fromJson(Map<String, dynamic> json) =>
      FundTransactionModel.fromMap(json);

  String toJsonString() => jsonEncode(toJson());

  factory FundTransactionModel.fromJsonString(String source) =>
      FundTransactionModel.fromJson(jsonDecode(source) as Map<String, dynamic>);

  FundTransactionModel copyWith({
    String? id,
    String? proofId,
    TransactionType? type,
    double? amount,
    String? title,
    String? category,
    String? proofImagePath,
    String? note,
    String? recipientOrSponsor,
    DateTime? createdAt,
  }) {
    return FundTransactionModel(
      id: id ?? this.id,
      proofId: proofId ?? this.proofId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      category: category ?? this.category,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      note: note ?? this.note,
      recipientOrSponsor: recipientOrSponsor ?? this.recipientOrSponsor,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FundTransactionModel &&
        other.id == id &&
        other.proofId == proofId &&
        other.type == type &&
        other.amount == amount &&
        other.title == title &&
        other.category == category &&
        other.proofImagePath == proofImagePath &&
        other.note == note &&
        other.recipientOrSponsor == recipientOrSponsor &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      proofId,
      type,
      amount,
      title,
      category,
      proofImagePath,
      note,
      recipientOrSponsor,
      createdAt,
    );
  }
}
