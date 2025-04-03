// lib/controllers/admin_auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_model.dart';

class AdminAuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<AdminModel?> currentAdmin = Rx<AdminModel?>(null);
  RxBool isLoading = false.obs;

  // 로그인 상태 확인
  bool get isLoggedIn => _auth.currentUser != null;

  @override
  void onInit() {
    super.onInit();
    // 인증 상태 변경 감지
    _auth.authStateChanges().listen(_handleAuthStateChange);
  }

  // 인증 상태 변경 처리
  void _handleAuthStateChange(User? user) async {
    if (user == null) {
      currentAdmin.value = null;
      return;
    }

    try {
      // 관리자 권한 확인
      DocumentSnapshot adminDoc =
          await _firestore.collection('admins').doc(user.uid).get();

      if (!adminDoc.exists) {
        // 관리자 아님
        await _auth.signOut();
        return;
      }

      // 관리자 정보 로드
      currentAdmin.value = AdminModel.fromFirestore(adminDoc);
    } catch (e) {
      print('관리자 정보 로드 오류: $e');
      await _auth.signOut();
    }
  }

  // 권한 체크 함수
  bool hasPermission(String permission) {
    if (currentAdmin.value == null) return false;
    if (currentAdmin.value!.role == AdminRole.superAdmin) return true;
    return currentAdmin.value!.permissions.contains(permission);
  }

  // 로그인
  Future<bool> signIn(String email, String password) async {
    try {
      isLoading.value = true;
      // Firebase 인증
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // 관리자 권한 확인
      DocumentSnapshot adminDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        // 관리자 아님
        await _auth.signOut();
        Get.snackbar(
          '접근 거부',
          '관리자 권한이 없습니다.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
        return false;
      }

      // 활성 상태 확인
      final adminData = adminDoc.data() as Map<String, dynamic>;
      if (!(adminData['isActive'] ?? true)) {
        // 비활성화된 계정
        await _auth.signOut();
        Get.snackbar(
          '접근 거부',
          '비활성화된 계정입니다. 관리자에게 문의하세요.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.1),
        );
        return false;
      }

      // 관리자 정보 로드
      currentAdmin.value = AdminModel.fromFirestore(adminDoc);

      // 로그인 기록 업데이트
      await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      // 활동 로그 기록
      await _logActivity('login', userCredential.user!.uid, 'admin', {},
          {'timestamp': FieldValue.serverTimestamp()});

      return true;
    } catch (e) {
      print('로그인 오류: $e');
      String errorMessage = '로그인 중 오류가 발생했습니다.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = '등록되지 않은 이메일입니다.';
            break;
          case 'wrong-password':
            errorMessage = '비밀번호가 일치하지 않습니다.';
            break;
          case 'invalid-email':
            errorMessage = '올바른 이메일 형식이 아닙니다.';
            break;
          case 'user-disabled':
            errorMessage = '비활성화된 계정입니다.';
            break;
        }
      }

      Get.snackbar(
        '로그인 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      if (currentAdmin.value != null) {
        await _logActivity('logout', currentAdmin.value!.uid, 'admin', {},
            {'timestamp': FieldValue.serverTimestamp()});
      }

      await _auth.signOut();
      currentAdmin.value = null;

      Get.snackbar(
        '로그아웃',
        '성공적으로 로그아웃되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );
    } catch (e) {
      print('로그아웃 오류: $e');
      Get.snackbar(
        '오류',
        '로그아웃 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 비밀번호 변경
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      isLoading.value = true;

      User? user = _auth.currentUser;
      if (user == null) return false;

      // 현재 비밀번호 확인을 위한 재인증
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // 비밀번호 변경
      await user.updatePassword(newPassword);

      // 활동 로그 기록
      await _logActivity('change_password', user.uid, 'admin', {},
          {'timestamp': FieldValue.serverTimestamp()});

      Get.snackbar(
        '비밀번호 변경',
        '비밀번호가 성공적으로 변경되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('비밀번호 변경 오류: $e');

      String errorMessage = '비밀번호 변경 중 오류가 발생했습니다.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = '현재 비밀번호가 일치하지 않습니다.';
            break;
          case 'weak-password':
            errorMessage = '새 비밀번호가 너무 약합니다.';
            break;
        }
      }

      Get.snackbar(
        '비밀번호 변경 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 이메일로 비밀번호 재설정 링크 전송
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;

      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        '비밀번호 재설정',
        '비밀번호 재설정 링크가 이메일로 전송되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('비밀번호 재설정 링크 전송 오류: $e');

      String errorMessage = '비밀번호 재설정 링크 전송 중 오류가 발생했습니다.';

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = '등록되지 않은 이메일입니다.';
            break;
          case 'invalid-email':
            errorMessage = '올바른 이메일 형식이 아닙니다.';
            break;
        }
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

  // 관리자 활동 로그 기록
  Future<void> _logActivity(String action, String targetId, String targetType,
      Map<String, dynamic> before, Map<String, dynamic> after) async {
    try {
      if (currentAdmin.value == null) return;

      await _firestore.collection('admin_logs').add({
        'adminId': currentAdmin.value!.uid,
        'adminName': currentAdmin.value!.name,
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

  // 다른 컨트롤러에서 활동 로그를 기록할 수 있도록 공개 메서드 제공
  Future<void> logActivity(String action, String targetId, String targetType,
      Map<String, dynamic> before, Map<String, dynamic> after) async {
    await _logActivity(action, targetId, targetType, before, after);
  }
}
