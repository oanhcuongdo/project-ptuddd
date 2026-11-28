/// Structured result from parsing a scanned or uploaded MoMo QR payload.
class MoMoQrParseResult {
  final String rawPayload;
  final String? phoneNumber;
  final String? recipientName;
  final String? deeplink;

  const MoMoQrParseResult({
    required this.rawPayload,
    this.phoneNumber,
    this.recipientName,
    this.deeplink,
  });

  bool get hasExtractedInfo =>
      (phoneNumber != null && phoneNumber!.isNotEmpty) ||
      (recipientName != null && recipientName!.isNotEmpty) ||
      (deeplink != null && deeplink!.isNotEmpty);

  String get displaySummary {
    final parts = <String>[];
    if (recipientName != null && recipientName!.isNotEmpty) {
      parts.add('Người nhận: $recipientName');
    }
    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      parts.add('SĐT: $phoneNumber');
    }
    if (deeplink != null && deeplink!.isNotEmpty) {
      parts.add('Link: $deeplink');
    }
    if (parts.isEmpty) {
      final preview =
          rawPayload.length > 48 ? '${rawPayload.substring(0, 48)}...' : rawPayload;
      return 'QR: $preview';
    }
    return parts.join(' • ');
  }
}

/// Pure domain helpers for MoMo Group Fund deeplinks, QR payloads, and transfer notes.
class MoMoDeeplinkHelper {
  const MoMoDeeplinkHelper._();

  /// Builds a standardized transfer note for a trip member's deposit.
  static String buildTransferNote({
    required String tripId,
    required String memberName,
  }) {
    final cleanTrip = tripId.trim().isEmpty ? 'TRIP' : tripId.trim();
    final cleanMember = memberName.trim().isEmpty ? 'Member' : memberName.trim();
    return 'TravelBuddy $cleanTrip - $cleanMember';
  }

  /// Builds a MoMo web/deeplink URL from a phone number if no custom deeplink is provided.
  static String buildFallbackLink(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return 'https://nhantien.momo.vn/$digits';
  }

  /// Extracts a usable raw QR string.
  static String parseScannedQr(String rawValue) {
    return rawValue.trim();
  }

  /// Parses common MoMo / VietQR payloads into structured fields:
  /// 1. MoMo transfer QR: `2|99|<phone>|<name>|<email>|0|0|<amount>|<note>|transfer_myqr`
  /// 2. MoMo URL / deeplink: `https://me.momo.vn/...`, `https://nhantien.momo.vn/<phone>`, `momo://...`
  /// 3. EMVCo / VietQR: `000201...` (extracts tag 59 merchant name & MoMo/phone if present)
  /// 4. Plain VN phone number: `09xxxxxxxx` / `+849xxxxxxxx`
  static MoMoQrParseResult parseMoMoQr(String rawValue) {
    final raw = rawValue.trim();
    if (raw.isEmpty) {
      return const MoMoQrParseResult(rawPayload: '');
    }

    // 1. MoMo pipe-delimited personal/transfer QR: 2|99|<phone>|<name>|...
    if (raw.contains('|')) {
      final parts = raw.split('|');
      if (parts.length >= 3 && (parts[0] == '2' || parts[0] == '1')) {
        final candidatePhone = _normalizeVnPhone(parts[2]);
        final candidateName =
            parts.length >= 4 && parts[3].trim().isNotEmpty ? parts[3].trim() : null;
        return MoMoQrParseResult(
          rawPayload: raw,
          phoneNumber: candidatePhone,
          recipientName: candidateName,
          deeplink: candidatePhone != null ? buildFallbackLink(candidatePhone) : null,
        );
      }
    }

    // 2. HTTP(S) or MoMo deeplink
    final lower = raw.toLowerCase();
    if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('momo://')) {
      final phoneMatch = RegExp(r'(0[35789]\d{8})').firstMatch(raw);
      final phone = phoneMatch?.group(1);
      return MoMoQrParseResult(
        rawPayload: raw,
        phoneNumber: phone,
        deeplink: raw,
      );
    }

    // 3. EMVCo / VietQR payload starting with 000201
    if (raw.startsWith('000201')) {
      final tlvs = _parseEmvTlv(raw);
      final merchantName = tlvs['59'];
      String? phone;

      // VietQR structure: Tag 38 -> Subtag 01 -> Subtag 01 holds beneficiary/MoMo account
      final tag38 = tlvs['38'];
      if (tag38 != null) {
        final sub38 = _parseEmvTlv(tag38);
        final sub01 = sub38['01'];
        if (sub01 != null) {
          final beneficiaryTlvs = _parseEmvTlv(sub01);
          final account = beneficiaryTlvs['01'];
          if (account != null) {
            phone = _normalizeVnPhone(account);
          }
        }
      }

      if (phone == null && tlvs['62'] != null) {
        final phoneMatch = RegExp(r'(0[35789]\d{8})').firstMatch(tlvs['62']!);
        phone = phoneMatch?.group(1);
      }

      return MoMoQrParseResult(
        rawPayload: raw,
        phoneNumber: phone,
        recipientName: merchantName,
        deeplink: phone != null ? buildFallbackLink(phone) : null,
      );
    }

    // 4. Plain phone number
    final normalizedPhone = _normalizeVnPhone(raw);
    if (normalizedPhone != null) {
      return MoMoQrParseResult(
        rawPayload: raw,
        phoneNumber: normalizedPhone,
        deeplink: buildFallbackLink(normalizedPhone),
      );
    }

    return MoMoQrParseResult(rawPayload: raw);
  }

  static String? _normalizeVnPhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-.]'), '');
    if (RegExp(r'^0[35789]\d{8}$').hasMatch(cleaned)) {
      return cleaned;
    }
    if (RegExp(r'^\+84[35789]\d{8}$').hasMatch(cleaned)) {
      return '0${cleaned.substring(3)}';
    }
    return null;
  }

  static Map<String, String> _parseEmvTlv(String payload) {
    final result = <String, String>{};
    var index = 0;
    while (index + 4 <= payload.length) {
      final tag = payload.substring(index, index + 2);
      final lenStr = payload.substring(index + 2, index + 4);
      final len = int.tryParse(lenStr);
      if (len == null || len < 0 || index + 4 + len > payload.length) {
        break;
      }
      result[tag] = payload.substring(index + 4, index + 4 + len);
      index += 4 + len;
    }
    return result;
  }

  /// Validates a Vietnamese phone number (10 digits starting with 0, or +84).
  static bool isValidPhoneNumber(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-.]'), '');
    return RegExp(r'^(0|\+84)\d{9}$').hasMatch(cleaned);
  }

  /// Formats an integer VND amount with dot separators (e.g. 212.000đ).
  static String formatVnd(int amount) {
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return '${amount < 0 ? '-' : ''}${buffer.toString()}đ';
  }

  /// Extracts up to two uppercase initials from a member's full name.
  static String formatInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts[parts.length - 2][0]}${parts.last[0]}'.toUpperCase();
  }
}
