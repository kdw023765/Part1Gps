/// 파트 4 (AI 서버)에서 요구하는 잔소리 생성용 데이터 요청 규격입니다.
/// 파트 1(위치 정보) + 파트 2(예산 정보)가 융합된 형태입니다.
class NaggingRequest {
  final String uid;              // 사용자 고유 식별자 (Firebase UID)
  final String zoneName;         // 방금 진입한 위험 지역의 이름
  final String zoneCategory;     // 방금 진입한 곳의 카테고리 (AI가 문구 생성할 때 참고함)
  final int todayBudget;         // 오늘 쓸 수 있는 남은 돈 (파트 2 데이터)
  final int remainingBudget;     // 이번 달 잔여 총 예산 (파트 2 데이터)
  final double budgetUsageRate;  // 현재 예산 소진율 (0.0 ~ 1.0) (파트 2 데이터)
  final DateTime enteredAt;      // 사용자가 위험 지역에 진입한 정확한 시간

  // 생성자
  NaggingRequest({
    required this.uid,
    required this.zoneName,
    required this.zoneCategory,
    required this.todayBudget,
    required this.remainingBudget,
    required this.budgetUsageRate,
    required this.enteredAt,
  });

  /// 이 객체를 파트 4의 FastAPI 서버로 HTTP 전송하기 위해 
  /// JSON 형식으로 변환해 주는 함수입니다.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'zoneName': zoneName,
      'zoneCategory': zoneCategory,
      'todayBudget': todayBudget,
      'remainingBudget': remainingBudget,
      'budgetUsageRate': budgetUsageRate,
      // DateTime 객체는 서버가 읽기 편하게 ISO 8601 문자열 규격으로 변환해서 보냅니다.
      'enteredAt': enteredAt.toIso8601String(),
    };
  }
}
