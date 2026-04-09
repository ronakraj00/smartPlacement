
class CollegeModel {
  final String id;
  final String name;
  final String code; // e.g. "IITP", "NITK"
  final String? logoUrl;
  final String? address;
  final String placementBatch; // e.g. "2025-26"
  final PlacementPolicy policy;

  CollegeModel({
    required this.id,
    required this.name,
    required this.code,
    this.logoUrl,
    this.address,
    this.placementBatch = '2025-26',
    required this.policy,
  });

  factory CollegeModel.fromMap(Map<String, dynamic> data, String docId) {
    return CollegeModel(
      id: docId,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      logoUrl: data['logoUrl'],
      address: data['address'],
      placementBatch: data['placementBatch'] ?? '2025-26',
      policy: PlacementPolicy.fromMap(data['policy'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'code': code,
    'logoUrl': logoUrl,
    'address': address,
    'placementBatch': placementBatch,
    'policy': policy.toMap(),
  };
}

class PlacementPolicy {
  final int maxOffers;
  final double dreamCtcThreshold;   // in LPA
  final double superDreamCtcThreshold;
  final bool blockAfterDream;
  final int allowedActiveBacklogs;
  final double minCgpa;
  final double minAttendance;

  PlacementPolicy({
    this.maxOffers = 1,
    this.dreamCtcThreshold = 15.0,
    this.superDreamCtcThreshold = 25.0,
    this.blockAfterDream = true,
    this.allowedActiveBacklogs = 0,
    this.minCgpa = 0.0,
    this.minAttendance = 0.0,
  });

  factory PlacementPolicy.fromMap(Map<String, dynamic> data) {
    return PlacementPolicy(
      maxOffers: data['maxOffers'] ?? 1,
      dreamCtcThreshold: (data['dreamCtcThreshold'] ?? 15.0).toDouble(),
      superDreamCtcThreshold: (data['superDreamCtcThreshold'] ?? 25.0).toDouble(),
      blockAfterDream: data['blockAfterDream'] ?? true,
      allowedActiveBacklogs: data['allowedActiveBacklogs'] ?? 0,
      minCgpa: (data['minCgpa'] ?? 0.0).toDouble(),
      minAttendance: (data['minAttendance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'maxOffers': maxOffers,
    'dreamCtcThreshold': dreamCtcThreshold,
    'superDreamCtcThreshold': superDreamCtcThreshold,
    'blockAfterDream': blockAfterDream,
    'allowedActiveBacklogs': allowedActiveBacklogs,
    'minCgpa': minCgpa,
    'minAttendance': minAttendance,
  };

  String classifyTier(double ctcLpa) {
    if (ctcLpa >= superDreamCtcThreshold) return 'Super Dream';
    if (ctcLpa >= dreamCtcThreshold) return 'Dream';
    return 'Normal';
  }
}
