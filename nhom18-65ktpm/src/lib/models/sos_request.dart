/// Ca cứu hộ SOS, tương ứng bảng `public.sos_requests`.
class SosRequest {
  const SosRequest({
    required this.id,
    required this.riderId,
    required this.issueType,
    required this.contactPhone,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.acceptedShopId,
    this.acceptedVolunteerId,
    this.note,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String riderId;
  final String? acceptedShopId;
  final String? acceptedVolunteerId;

  /// Hết xăng | Thủng lốp | Hỏng động cơ | Khác
  final String issueType;
  final String? note;
  final String contactPhone;
  final double latitude;
  final double longitude;

  /// pending | accepted | completed | cancelled
  final String status;
  final DateTime? createdAt;
  final DateTime? completedAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  factory SosRequest.fromMap(Map<String, dynamic> map) {
    return SosRequest(
      id: map['id'].toString(),
      riderId: map['rider_id']?.toString() ?? '',
      acceptedShopId: map['accepted_shop_id']?.toString(),
      acceptedVolunteerId: map['accepted_volunteer_id']?.toString(),
      issueType: map['issue_type']?.toString() ?? 'Khác',
      note: map['note']?.toString(),
      contactPhone: map['contact_phone']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      status: map['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
      completedAt: DateTime.tryParse(map['completed_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issue_type': issueType,
      'note': note,
      'contact_phone': contactPhone,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
