/// Ánh xạ bảng `user_accounts` (1 users -> N phương thức đăng nhập: Google, SĐT, Email)
class UserAccountModel {
  final String id;
  final String userId;
  final String provider;
  final String providerAccountId;
  final String? firebaseUid;
  final String? email;
  final String? phoneNumber;
  final bool isVerified;

  const UserAccountModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.providerAccountId,
    this.firebaseUid,
    this.email,
    this.phoneNumber,
    this.isVerified = false,
  });

  factory UserAccountModel.fromMap(Map<String, dynamic> map) {
    return UserAccountModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      provider: map['provider'] as String? ?? 'email',
      providerAccountId: map['provider_account_id'] as String? ?? '',
      firebaseUid: map['firebase_uid'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phone_number'] as String?,
      isVerified: map['is_verified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'provider': provider,
      'provider_account_id': providerAccountId,
      'firebase_uid': firebaseUid,
      'email': email,
      'phone_number': phoneNumber,
      'is_verified': isVerified,
    };
  }
}
