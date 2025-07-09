class ApiUsageModel {
  final String userId;
  final DateTime? lastRequest;
  final int minuteCount;
  final int dailyCount;
  final DateTime lastReset;

  ApiUsageModel({
    required this.userId,
    this.lastRequest,
    required this.minuteCount,
    required this.dailyCount,
    required this.lastReset,
  });
}
