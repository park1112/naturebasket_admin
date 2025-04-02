// lib/services/admin_service.dart (계속)
      await _firestore
          .collection('admins')
          .doc(adminId)
          .update({'isActive': true});
          
      return true;
    } catch (e) {
      print('관리자 활성화 오류: $e');
      Get.snackbar(
        '오류',
        '관리자 활성화 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return false;
    }
  }
  
  // 관리자 활동 로그 조회
  Future<List<AdminActivityLog>> getActivityLogs({
    String? adminId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('admin_logs')
          .orderBy('timestamp', descending: true);
          
      if (adminId != null) {
        query = query.where('adminId', isEqualTo: adminId);
      }
      
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }
      
      if (startDate != null) {
        query = query.where('timestamp', 
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('timestamp', 
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      query = query.limit(limit);
      
      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => AdminActivityLog.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('활동 로그 조회 오류: $e');
      Get.snackbar(
        '오류',
        '활동 로그를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return [];
    }
  }
  
  // 활동 로그 기록
  Future<void> logActivity(
    String adminId,
    String adminName,
    String action,
    String targetId,
    String targetType,
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) async {
    try {
      await _firestore.collection('admin_logs').add({
        'adminId': adminId,
        'adminName': adminName,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'before': before,
        'after': after,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('활동 로그 기록 오류: $e');
    }
  }
}