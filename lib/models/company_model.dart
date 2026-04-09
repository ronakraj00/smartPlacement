class CompanyModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String industry;
  final String? website;
  final String description;
  final String? headquarters;
  final String? employeeCount;
  final double avgRating;
  final List<String> pastVisitYears;

  CompanyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    this.industry = '',
    this.website,
    this.description = '',
    this.headquarters,
    this.employeeCount,
    this.avgRating = 0.0,
    this.pastVisitYears = const [],
  });

  factory CompanyModel.fromMap(Map<String, dynamic> data, String docId) {
    return CompanyModel(
      id: docId,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'],
      industry: data['industry'] ?? '',
      website: data['website'],
      description: data['description'] ?? '',
      headquarters: data['headquarters'],
      employeeCount: data['employeeCount'],
      avgRating: (data['avgRating'] ?? 0.0).toDouble(),
      pastVisitYears: data['pastVisitYears'] != null
          ? List<String>.from(data['pastVisitYears'])
          : [],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'logoUrl': logoUrl,
    'industry': industry,
    'website': website,
    'description': description,
    'headquarters': headquarters,
    'employeeCount': employeeCount,
    'avgRating': avgRating,
    'pastVisitYears': pastVisitYears,
  };
}
