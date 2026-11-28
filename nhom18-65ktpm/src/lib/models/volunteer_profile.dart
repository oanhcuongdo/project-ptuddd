/// Hồ sơ tình nguyện viên, tương ứng bảng `public.volunteer_profiles`.
class VolunteerProfile {
  const VolunteerProfile({
    required this.id,
    required this.userId,
    required this.phone,
    required this.skills,
    required this.idCardUrl,
    required this.serviceRadiusKm,
    required this.isAvailable,
    required this.status,
    required this.completedCount,
    this.rejectionReason,
    this.tools,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String phone;
  final List<String> skills;
  final String? tools;
  final String idCardUrl;
  final int serviceRadiusKm;
  final bool isAvailable;

  /// pending | approved | rejected | banned
  final String status;
  final String? rejectionReason;
  final int completedCount;
  final DateTime? createdAt;

  factory VolunteerProfile.fromMap(Map<String, dynamic> map) {
    return VolunteerProfile(
      id: map['id'].toString(),
      userId: map['user_id']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      skills: (map['skills'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      tools: map['tools']?.toString(),
      idCardUrl: map['id_card_url']?.toString() ?? '',
      serviceRadiusKm: (map['service_radius_km'] as num?)?.toInt() ?? 5,
      isAvailable: map['is_available'] as bool? ?? false,
      status: map['status']?.toString() ?? 'pending',
      rejectionReason: map['rejection_reason']?.toString(),
      completedCount: (map['completed_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'phone': phone,
      'skills': skills,
      'tools': tools,
      'id_card_url': idCardUrl,
      'service_radius_km': serviceRadiusKm,
      'is_available': isAvailable,
    };
  }
}
