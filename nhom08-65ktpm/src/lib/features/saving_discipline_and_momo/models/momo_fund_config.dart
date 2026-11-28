import 'package:cloud_firestore/cloud_firestore.dart';

class MoMoFundConfig {
  final String tripId;
  final String fundName;
  final String hostUserId;
  final String hostName;
  final String momoPhoneNumber;
  final String? momoFundDeeplink;
  final String? qrCodeUrl;
  final double targetTotalAmount;
  final double currentCollectedAmount;
  final String currency;
  final DateTime updatedAt;

  const MoMoFundConfig({
    required this.tripId,
    required this.fundName,
    required this.hostUserId,
    required this.hostName,
    required this.momoPhoneNumber,
    this.momoFundDeeplink,
    this.qrCodeUrl,
    required this.targetTotalAmount,
    this.currentCollectedAmount = 0.0,
    this.currency = 'VND',
    required this.updatedAt,
  });

  factory MoMoFundConfig.fromMap(Map<String, dynamic> map, {String? tripId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return MoMoFundConfig(
      tripId: tripId ?? (map['tripId'] as String? ?? ''),
      fundName: map['fundName'] as String? ?? '',
      hostUserId: map['hostUserId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? '',
      momoPhoneNumber: map['momoPhoneNumber'] as String? ?? '',
      momoFundDeeplink: map['momoFundDeeplink'] as String?,
      qrCodeUrl: map['qrCodeUrl'] as String?,
      targetTotalAmount: (map['targetTotalAmount'] as num?)?.toDouble() ?? 0.0,
      currentCollectedAmount: (map['currentCollectedAmount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'VND',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'fundName': fundName,
      'hostUserId': hostUserId,
      'hostName': hostName,
      'momoPhoneNumber': momoPhoneNumber,
      if (momoFundDeeplink != null) 'momoFundDeeplink': momoFundDeeplink,
      if (qrCodeUrl != null) 'qrCodeUrl': qrCodeUrl,
      'targetTotalAmount': targetTotalAmount,
      'currentCollectedAmount': currentCollectedAmount,
      'currency': currency,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MoMoFundConfig copyWith({
    String? tripId,
    String? fundName,
    String? hostUserId,
    String? hostName,
    String? momoPhoneNumber,
    String? momoFundDeeplink,
    String? qrCodeUrl,
    double? targetTotalAmount,
    double? currentCollectedAmount,
    String? currency,
    DateTime? updatedAt,
  }) {
    return MoMoFundConfig(
      tripId: tripId ?? this.tripId,
      fundName: fundName ?? this.fundName,
      hostUserId: hostUserId ?? this.hostUserId,
      hostName: hostName ?? this.hostName,
      momoPhoneNumber: momoPhoneNumber ?? this.momoPhoneNumber,
      momoFundDeeplink: momoFundDeeplink ?? this.momoFundDeeplink,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      targetTotalAmount: targetTotalAmount ?? this.targetTotalAmount,
      currentCollectedAmount: currentCollectedAmount ?? this.currentCollectedAmount,
      currency: currency ?? this.currency,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
