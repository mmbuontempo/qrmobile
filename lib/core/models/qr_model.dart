class QrModel {
  final String id;
  final String name;
  final String slug;
  final String shortCode;
  final String? targetUrl;
  final bool isActive;
  final bool showInterstitial;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? folderId;
  final MicrositeModel? microsite;
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;

  QrModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.shortCode,
    this.targetUrl,
    required this.isActive,
    required this.showInterstitial,
    required this.createdAt,
    required this.updatedAt,
    this.folderId,
    this.microsite,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
  });

  factory QrModel.fromJson(Map<String, dynamic> json) {
    return QrModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      shortCode: json['shortCode'] ?? '',
      targetUrl: json['targetUrl'],
      isActive: json['isActive'] ?? true,
      showInterstitial: json['showInterstitial'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      folderId: json['folderId'],
      microsite: json['microsite'] != null 
          ? MicrositeModel.fromJson(json['microsite']) 
          : null,
      utmSource: json['utmSource'],
      utmMedium: json['utmMedium'],
      utmCampaign: json['utmCampaign'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'slug': slug,
    'targetUrl': targetUrl,
    'isActive': isActive,
    'showInterstitial': showInterstitial,
    'folderId': folderId,
    'utmSource': utmSource,
    'utmMedium': utmMedium,
    'utmCampaign': utmCampaign,
  };

  String get qrUrl => '${const String.fromEnvironment('QR_BASE_URL', defaultValue: 'https://promuslink.com/c/')}$shortCode';
  
  QrModel copyWith({
    String? name,
    String? slug,
    String? targetUrl,
    bool? isActive,
    bool? showInterstitial,
    String? folderId,
  }) {
    return QrModel(
      id: id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      shortCode: shortCode,
      targetUrl: targetUrl ?? this.targetUrl,
      isActive: isActive ?? this.isActive,
      showInterstitial: showInterstitial ?? this.showInterstitial,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      folderId: folderId ?? this.folderId,
      microsite: microsite,
      utmSource: utmSource,
      utmMedium: utmMedium,
      utmCampaign: utmCampaign,
    );
  }
}

class MicrositeModel {
  final String id;
  final String title;
  final String? description;
  final String? heroImageUrl;
  final String? logoUrl;
  final String ctaType;
  final String ctaLabel;
  final String ctaValue;
  final String template;

  MicrositeModel({
    required this.id,
    required this.title,
    this.description,
    this.heroImageUrl,
    this.logoUrl,
    required this.ctaType,
    required this.ctaLabel,
    required this.ctaValue,
    required this.template,
  });

  factory MicrositeModel.fromJson(Map<String, dynamic> json) {
    return MicrositeModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      heroImageUrl: json['heroImageUrl'],
      logoUrl: json['logoUrl'],
      ctaType: json['ctaType'] ?? 'LINK',
      ctaLabel: json['ctaLabel'] ?? '',
      ctaValue: json['ctaValue'] ?? '',
      template: json['template'] ?? 'PROMO_V1',
    );
  }
}
