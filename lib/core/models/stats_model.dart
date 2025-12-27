class StatsModel {
  final int totalQrs;
  final int activeQrs;
  final int totalScans;
  final int scansToday;
  final int scansThisWeek;
  final int scansThisMonth;
  final List<DailyScan> dailyScans;
  
  // Plan Info (agregado según auditoría)
  final String? planName;
  final int? qrLimit;
  final int? qrUsed;
  final int? qrRemaining;

  StatsModel({
    required this.totalQrs,
    required this.activeQrs,
    required this.totalScans,
    required this.scansToday,
    required this.scansThisWeek,
    required this.scansThisMonth,
    required this.dailyScans,
    this.planName,
    this.qrLimit,
    this.qrUsed,
    this.qrRemaining,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    final dailyScansData = json['dailyScans'] as List<dynamic>? ?? [];
    
    return StatsModel(
      totalQrs: json['totalQrs'] ?? 0,
      activeQrs: json['activeQrs'] ?? 0,
      totalScans: json['totalScans'] ?? 0,
      scansToday: json['scansToday'] ?? 0,
      scansThisWeek: json['scansThisWeek'] ?? 0,
      scansThisMonth: json['scansThisMonth'] ?? 0,
      dailyScans: dailyScansData
          .map((e) => DailyScan.fromJson(e as Map<String, dynamic>))
          .toList(),
      planName: json['planName'],
      qrLimit: json['qrLimit'],
      qrUsed: json['qrUsed'],
      qrRemaining: json['qrRemaining'],
    );
  }

  factory StatsModel.empty() => StatsModel(
    totalQrs: 0,
    activeQrs: 0,
    totalScans: 0,
    scansToday: 0,
    scansThisWeek: 0,
    scansThisMonth: 0,
    dailyScans: [],
    planName: 'Starter',
    qrLimit: 1,
    qrUsed: 0,
    qrRemaining: 1,
  );
}

class DailyScan {
  final DateTime date;
  final int count;

  DailyScan({required this.date, required this.count});

  factory DailyScan.fromJson(Map<String, dynamic> json) {
    return DailyScan(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      count: json['count'] ?? 0,
    );
  }
}
