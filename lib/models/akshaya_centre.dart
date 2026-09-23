class AkshayaCentre {
  final String id;
  final String district;
  final String nameEn;
  final String nameMl;
  final String panchayatEn;
  final String panchayatMl;
  final String locationEn;
  final String locationMl;
  final String contactPerson;
  final String phone;
  final String email;
  final List<String> services;

  const AkshayaCentre({
    required this.id,
    required this.district,
    required this.nameEn,
    required this.nameMl,
    required this.panchayatEn,
    required this.panchayatMl,
    required this.locationEn,
    required this.locationMl,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.services,
  });

  factory AkshayaCentre.fromJson(Map<String, dynamic> json) {
    return AkshayaCentre(
      id: json['id'] as String,
      district: json['district'] as String,
      nameEn: json['nameEn'] as String,
      nameMl: json['nameMl'] as String,
      panchayatEn: json['panchayatEn'] as String? ?? '',
      panchayatMl: json['panchayatMl'] as String? ?? '',
      locationEn: json['locationEn'] as String? ?? '',
      locationMl: json['locationMl'] as String? ?? '',
      contactPerson: json['contactPerson'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  String getName(bool isMalayalam) => isMalayalam ? nameMl : nameEn;
  String getPanchayat(bool isMalayalam) => isMalayalam ? panchayatMl : panchayatEn;
  String getLocation(bool isMalayalam) => isMalayalam ? locationMl : locationEn;
}
