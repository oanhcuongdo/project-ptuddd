import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/utils/timestamp_converter.dart';

part 'checklist_item.freezed.dart';
part 'checklist_item.g.dart';

enum ChecklistPhase {
  @JsonValue('before_30d')
  before30d,
  @JsonValue('before_14d')
  before14d,
  @JsonValue('before_3d')
  before3d,
  @JsonValue('packing')
  packing,
}

enum ChecklistScope {
  @JsonValue('group')
  group,
  @JsonValue('personal')
  personal,
}

extension ChecklistPhaseX on ChecklistPhase {
  String get label => switch (this) {
        ChecklistPhase.before30d => 'Trước 30 ngày • Đặt vé & Phòng',
        ChecklistPhase.before14d => 'Trước 14 ngày • Mua sắm & Thủ tục',
        ChecklistPhase.before3d => 'Trước 1–3 ngày • Chốt cuối',
        ChecklistPhase.packing => 'Hành lý & Đồ dùng mang theo',
      };

  String get shortLabel => switch (this) {
        ChecklistPhase.before30d => 'Trước 30 ngày',
        ChecklistPhase.before14d => 'Trước 14 ngày',
        ChecklistPhase.before3d => 'Trước 1–3 ngày',
        ChecklistPhase.packing => 'Hành lý',
      };

  int get defaultDaysBeforeDeparture => switch (this) {
        ChecklistPhase.before30d => 21,
        ChecklistPhase.before14d => 7,
        ChecklistPhase.before3d => 2,
        ChecklistPhase.packing => 1,
      };

  bool get isPacking => this == ChecklistPhase.packing;
}

@freezed
abstract class ChecklistItem with _$ChecklistItem {
  const ChecklistItem._();

  const factory ChecklistItem({
    required String id,
    required String tripId,
    required String title,
    String? description,
    @Default(ChecklistPhase.before14d) ChecklistPhase phase,
    @Default(ChecklistScope.group) ChecklistScope scope,
    String? ownerId,
    String? assigneeId,
    String? assigneeName,
    @NullableTimestampConverter() DateTime? dueDate,
    @Default(false) bool isCompleted,
    @NullableTimestampConverter() DateTime? completedAt,
    String? completedBy,
    String? proofImageUrl,
    String? proofStoragePath,
    @Default(0) int sortOrder,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
  }) = _ChecklistItem;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemFromJson(json);

  bool get hasProofPhoto =>
      proofImageUrl != null && proofImageUrl!.trim().isNotEmpty;

  bool isOverdue([DateTime? now]) {
    if (isCompleted || dueDate == null) return false;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueDay.isBefore(today);
  }

  bool isDueSoon([DateTime? now]) {
    if (isCompleted || dueDate == null) return false;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final diff = dueDay.difference(today).inDays;
    return diff >= 0 && diff <= 2;
  }
}

class ChecklistTemplateItem {
  const ChecklistTemplateItem({
    required this.title,
    required this.phase,
    this.scope = ChecklistScope.group,
    this.daysBeforeDeparture,
  });

  final String title;
  final ChecklistPhase phase;
  final ChecklistScope scope;
  final int? daysBeforeDeparture;

  factory ChecklistTemplateItem.fromMap(Map<String, dynamic> map) {
    final phaseStr = map['phase'] as String? ?? 'before_14d';
    final scopeStr = map['scope'] as String? ?? 'group';
    return ChecklistTemplateItem(
      title: map['title'] as String? ?? '',
      phase: ChecklistPhase.values.firstWhere(
        (e) => switch (e) {
          ChecklistPhase.before30d => 'before_30d',
          ChecklistPhase.before14d => 'before_14d',
          ChecklistPhase.before3d => 'before_3d',
          ChecklistPhase.packing => 'packing',
        } ==
            phaseStr,
        orElse: () => ChecklistPhase.before14d,
      ),
      scope: scopeStr == 'personal'
          ? ChecklistScope.personal
          : ChecklistScope.group,
      daysBeforeDeparture: (map['daysBeforeDeparture'] as num?)?.toInt(),
    );
  }
}

class ChecklistTemplate {
  const ChecklistTemplate({
    required this.id,
    required this.tripType,
    required this.name,
    required this.subtitle,
    required this.items,
  });

  final String id;
  final String tripType;
  final String name;
  final String subtitle;
  final List<ChecklistTemplateItem> items;
}
