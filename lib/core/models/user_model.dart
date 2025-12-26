class CompanyModel {
  final String id;
  final String name;
  final String slug;

  CompanyModel({required this.id, required this.name, required this.slug});

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    slug: json['slug'] ?? '',
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String role;
  final String? companyId;
  final bool isActive;
  final CompanyModel? company;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    required this.role,
    this.companyId,
    this.isActive = true,
    this.company,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      avatarUrl: json['avatarUrl'],
      role: json['role'] ?? 'USER',
      companyId: json['companyId'],
      isActive: json['isActive'] ?? true,
      company: json['company'] != null ? CompanyModel.fromJson(json['company']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'avatarUrl': avatarUrl,
    'role': role,
    'companyId': companyId,
    'isActive': isActive,
    'company': company?.toJson(),
  };

  bool get isSuperUser => role == 'SUPERUSER';
  bool get isAdmin => role == 'ADMIN' || isSuperUser;
}
