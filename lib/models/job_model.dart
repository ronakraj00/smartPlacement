class JobModel {
  final String id;
  final String title;
  final String company;
  final String location;
  final String description;
  final String salary;
  final List<String> requirements;
  final DateTime postedAt;
  final bool isRemote;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.salary,
    required this.requirements,
    required this.postedAt,
    this.isRemote = false,
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      description: json['description'] as String,
      salary: json['salary'] as String,
      requirements: List<String>.from(json['requirements'] as List),
      postedAt: DateTime.parse(json['postedAt'] as String),
      isRemote: json['isRemote'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'salary': salary,
      'requirements': requirements,
      'postedAt': postedAt.toIso8601String(),
      'isRemote': isRemote,
    };
  }
}
