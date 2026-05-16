class NaggingRequest {
  final String uid;
  final String zoneName;
  final String zoneCategory;
  final int todayBudget;
  final int remainingBudget;
  final double budgetUsageRate;
  final DateTime enteredAt;

  NaggingRequest({
    required this.uid,
    required this.zoneName,
    required this.zoneCategory,
    required this.todayBudget,
    required this.remainingBudget,
    required this.budgetUsageRate,
    required this.enteredAt,
  });
}
