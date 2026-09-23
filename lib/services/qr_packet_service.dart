import 'dart:convert';
import '../models/household_profile.dart';

class QrPacketData {
  final HouseholdProfile profile;
  final List<String> matchedSchemeIds;
  final DateTime timestamp;

  const QrPacketData({
    required this.profile,
    required this.matchedSchemeIds,
    required this.timestamp,
  });
}

/// Zero-PII offline serializer for generating and parsing Akshaya Fast-Track QR packets.
class QrPacketService {
  /// Encodes profile and matched scheme IDs into a compact offline QR payload.
  static String encodePacket({
    required HouseholdProfile profile,
    required List<String> matchedSchemeIds,
  }) {
    final map = {
      'v': 1,
      't': DateTime.now().millisecondsSinceEpoch,
      'p': {
        'occ': profile.occupation ?? '',
        'age': profile.age ?? 0,
        'dist': profile.district ?? '',
        'inc': profile.monthlyIncome ?? 0,
        'bm': profile.isBoardMember == true ? 1 : (profile.isBoardMember == false ? 0 : -1),
        'yr': profile.yearsOfMembership ?? 0,
        'rc': profile.rationCardCategory ?? '',
        'hc': profile.housingCondition ?? '',
        'sc': profile.hasStudentChild == true ? 1 : (profile.hasStudentChild == false ? 0 : -1),
      },
      's': matchedSchemeIds,
    };

    final jsonStr = jsonEncode(map);
    final bytes = utf8.encode(jsonStr);
    return 'WS:${base64Url.encode(bytes)}';
  }

  /// Decodes a QR payload back into a structured QrPacketData object.
  static QrPacketData? decodePacket(String payload) {
    try {
      if (!payload.startsWith('WS:')) return null;
      final rawBase64 = payload.substring(3);
      final jsonStr = utf8.decode(base64Url.decode(rawBase64));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      final pMap = map['p'] as Map<String, dynamic>;
      final profile = HouseholdProfile(
        occupation: pMap['occ'] != '' ? pMap['occ'] as String? : null,
        age: (pMap['age'] as num?)?.toInt() != 0 ? (pMap['age'] as num?)?.toInt() : null,
        district: pMap['dist'] != '' ? pMap['dist'] as String? : null,
        monthlyIncome: (pMap['inc'] as num?)?.toInt() != 0 ? (pMap['inc'] as num?)?.toInt() : null,
        isBoardMember: pMap['bm'] == 1 ? true : (pMap['bm'] == 0 ? false : null),
        yearsOfMembership: (pMap['yr'] as num?)?.toInt() != 0 ? (pMap['yr'] as num?)?.toInt() : null,
        rationCardCategory: pMap['rc'] != '' ? pMap['rc'] as String? : null,
        housingCondition: pMap['hc'] != '' ? pMap['hc'] as String? : null,
        hasStudentChild: pMap['sc'] == 1 ? true : (pMap['sc'] == 0 ? false : null),
      );

      final schemeIds = (map['s'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final ts = (map['t'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

      return QrPacketData(
        profile: profile,
        matchedSchemeIds: schemeIds,
        timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      return null;
    }
  }
}
