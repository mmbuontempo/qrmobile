class PlanFeatures {
  final bool microsites;
  final bool analytics;
  final bool folders;
  final bool export;
  final bool customDomain;
  final bool apiAccess;

  PlanFeatures({
    required this.microsites,
    required this.analytics,
    required this.folders,
    required this.export,
    required this.customDomain,
    required this.apiAccess,
  });

  factory PlanFeatures.fromJson(Map<String, dynamic> json) {
    return PlanFeatures(
      microsites: json['microsites'] ?? false,
      analytics: json['analytics'] ?? false,
      folders: json['folders'] ?? false,
      export: json['export'] ?? false,
      customDomain: json['customDomain'] ?? false,
      apiAccess: json['apiAccess'] ?? false,
    );
  }
}

class SubscriptionModel {
  final String planKey;
  final String planName;
  final bool isPaid;
  final DateTime? paidUntil;
  final int qrLimit;
  final int qrUsed;
  final int qrRemaining;
  final PlanFeatures features;

  SubscriptionModel({
    required this.planKey,
    required this.planName,
    required this.isPaid,
    this.paidUntil,
    required this.qrLimit,
    required this.qrUsed,
    required this.qrRemaining,
    required this.features,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      planKey: json['planKey'] ?? 'free',
      planName: json['planName'] ?? 'Starter',
      isPaid: json['isPaid'] ?? false,
      paidUntil: json['paidUntil'] != null ? DateTime.tryParse(json['paidUntil']) : null,
      qrLimit: json['qrLimit'] ?? 0,
      qrUsed: json['qrUsed'] ?? 0,
      qrRemaining: json['qrRemaining'] ?? 0,
      features: PlanFeatures.fromJson(json['features'] ?? {}),
    );
  }
}
