// lib/models/admin_activity_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityLog {
  final String id;
  final String adminId;
  final String adminName;
  final String action; // 어떤 작업을 했는지 (상품 추가, 주문 상태 변경 등)
  final String targetId; // 영향을 받은 문서 ID
  final String targetType; // 대상 유형 (product, order 등)
  final Map<String, dynamic> before; // 변경 전 데이터
  final Map<String, dynamic> after; // 변경 후 데이터
  final DateTime timestamp;

  AdminActivityLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.targetId,
    required this.targetType,
    required this.before,
    required this.after,
    required this.timestamp,
  });

  // Firestore에서 데이터 로드
  factory AdminActivityLog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminActivityLog(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      action: data['action'] ?? '',
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      before: data['before'] ?? {},
      after: data['after'] ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장하기 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'action': action,
      'targetId': targetId,
      'targetType': targetType,
      'before': before,
      'after': after,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
