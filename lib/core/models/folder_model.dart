class FolderModel {
  final String id;
  final String name;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int qrCount;

  FolderModel({
    required this.id,
    required this.name,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
    this.qrCount = 0,
  });

  factory FolderModel.fromJson(Map<String, dynamic> json) {
    return FolderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'],
      icon: json['icon'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      qrCount: json['_count']?['qrs'] ?? json['qrCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': color,
    'icon': icon,
  };
}
