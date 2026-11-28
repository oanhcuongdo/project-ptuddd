import 'package:flutter/material.dart';

class BudgetEnvelope {
  const BudgetEnvelope({
    required this.id,
    required this.category,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.allocatedAmount,
    required this.plannedFromItinerary,
    required this.spentAmount,
  });

  final String id;
  final String category;
  final String name;
  final String iconCode;
  final String colorHex;
  final int allocatedAmount;
  final int plannedFromItinerary;
  final int spentAmount;

  int get remainingAmount => allocatedAmount - spentAmount;

  Color get color {
    final value = int.tryParse(colorHex.replaceFirst('#', ''), radix: 16);
    return value == null ? const Color(0xFF0F766E) : Color(0xFF000000 | value);
  }

  factory BudgetEnvelope.fromFirestore(String id, Map<String, dynamic> data) {
    return BudgetEnvelope(
      id: id,
      category: data['category'] as String? ?? id,
      name: data['name'] as String? ?? id,
      iconCode: data['iconCode'] as String? ?? 'account_balance_wallet',
      colorHex: data['colorHex'] as String? ?? '#0F766E',
      allocatedAmount: (data['allocatedAmount'] as num?)?.round() ?? 0,
      plannedFromItinerary:
          (data['plannedFromItinerary'] as num?)?.round() ?? 0,
      spentAmount: (data['spentAmount'] as num?)?.round() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'category': category,
    'name': name,
    'iconCode': iconCode,
    'colorHex': colorHex,
    'allocatedAmount': allocatedAmount,
    'plannedFromItinerary': plannedFromItinerary,
    'spentAmount': spentAmount,
  };

  static const defaults = <_EnvelopeDefault>[
    _EnvelopeDefault(
      id: 'transport',
      name: 'Di chuyển',
      iconCode: 'directions_car',
      colorHex: '#0F766E',
      weight: 19,
    ),
    _EnvelopeDefault(
      id: 'accommodation',
      name: 'Lưu trú',
      iconCode: 'hotel',
      colorHex: '#0284C7',
      weight: 38,
    ),
    _EnvelopeDefault(
      id: 'food',
      name: 'Ăn uống',
      iconCode: 'restaurant',
      colorHex: '#EA580C',
      weight: 28,
    ),
    _EnvelopeDefault(
      id: 'tickets',
      name: 'Vé',
      iconCode: 'confirmation_number',
      colorHex: '#10B981',
      weight: 9,
    ),
    _EnvelopeDefault(
      id: 'shopping',
      name: 'Mua sắm',
      iconCode: 'shopping_bag',
      colorHex: '#D97706',
      weight: 2,
    ),
    _EnvelopeDefault(
      id: 'contingency',
      name: 'Dự phòng',
      iconCode: 'shield',
      colorHex: '#64748B',
      weight: 4,
    ),
  ];
}

class _EnvelopeDefault {
  const _EnvelopeDefault({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.weight,
  });

  final String id;
  final String name;
  final String iconCode;
  final String colorHex;
  final int weight;
}
