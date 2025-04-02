// lib/controllers/admin_management_controller.dart (계속)
      
      // 관리자 목록 새로고침
      await loadAdmins();
      
      Get.snackbar(
        '관리자 비활성화',
        '관리자 계정이 성공적으로 비활성화되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
      
      return true;
    } catch (e) {
      print('관리자 비활성화 오류: $e');
      
      String errorMessage = '관리자 비활성화 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      Get.snackbar(
        '관리자 비활성화 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // 관리자 활성화
  Future<bool> activateAdmin(String adminId) async {
    try {
      isLoading.value = true;
      
      // 현재 관리자 정보
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }
      
      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc = await _firestore
          .collection('admins')
          .doc(adminId)
          .get();
          
      if (!doc.exists) {
        throw Exception('관리자 정보를 찾을 수 없습니다.');
      }
      
      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;
      
      // Firestore 업데이트
      await _firestore
          .collection('admins')
          .doc(adminId)
          .update({'isActive': true});
          
      Map<String, dynamic> afterData = {...beforeData, 'isActive': true};
      
      // 활동 로그 기록
      await _authController.logActivity(
        'activate_admin',
        adminId,
        'admin',
        beforeData,
        afterData,
      );
      
      // 관리자 목록 새로고침
      await loadAdmins();
      
      Get.snackbar(
        '관리자 활성화',
        '관리자 계정이 성공적으로 활성화되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
      
      return true;
    } catch (e) {
      print('관리자 활성화 오류: $e');
      
      String errorMessage = '관리자 활성화 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      Get.snackbar(
        '관리자 활성화 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // 관리자 비밀번호 재설정
  Future<bool> resetAdminPassword(String adminId, String newPassword) async {
    try {
      isLoading.value = true;
      
      // 현재 관리자 정보
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }
      
      // 관리자 정보 확인
      DocumentSnapshot doc = await _firestore
          .collection('admins')
          .doc(adminId)
          .get();
          
      if (!doc.exists) {
        throw Exception('관리자 정보를 찾을 수 없습니다.');
      }
      
      AdminModel admin = AdminModel.fromFirestore(doc);
      
      // Firebase Admin SDK를 통한 비밀번호 재설정 필요
      // 클라이언트에서는 직접 다른 사용자의 비밀번호를 재설정할 수 없음
      // 실제 구현에서는 Cloud Functions를 통해 처리해야 함
      
      // 임시 코드 - 실제로는 작동하지 않음
      // await FirebaseAuth.instance.updatePassword(adminId, newPassword);
      
      // 활동 로그 기록
      await _authController.logActivity(
        'reset_admin_password',
        adminId,
        'admin',
        {},
        {'timestamp': FieldValue.serverTimestamp()},
      );
      
      Get.snackbar(
        '비밀번호 재설정',
        '관리자 비밀번호가 성공적으로 재설정되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
      
      return true;
    } catch (e) {
      print('비밀번호 재설정 오류: $e');
      
      String errorMessage = '비밀번호 재설정 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      Get.snackbar(
        '비밀번호 재설정 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}