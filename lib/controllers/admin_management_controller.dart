// lib/controllers/admin_management_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_model.dart';
import '../models/admin_activity_log.dart';
import 'admin_auth_controller.dart';

class AdminManagementController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AdminAuthController _authController = Get.find<AdminAuthController>();

  RxList<AdminModel> admins = <AdminModel>[].obs;
  RxList<AdminActivityLog> activityLogs = <AdminActivityLog>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadAdmins();
  }

  // 관리자 목록 로드
  Future<void> loadAdmins() async {
    try {
      isLoading.value = true;

      // Firestore에서 관리자 문서 가져오기
      QuerySnapshot snapshot = await _firestore.collection('admins').get();

      // 관리자 목록 생성
      List<AdminModel> loadedAdmins =
          snapshot.docs.map((doc) => AdminModel.fromFirestore(doc)).toList();

      // 최고 관리자가 먼저 오도록 정렬
      loadedAdmins.sort((a, b) {
        if (a.role == AdminRole.superAdmin) return -1;
        if (b.role == AdminRole.superAdmin) return 1;
        return a.name.compareTo(b.name);
      });

      // 관리자 목록 업데이트
      admins.value = loadedAdmins;
    } catch (e) {
      print('관리자 목록 로드 오류: $e');
      Get.snackbar(
        '오류',
        '관리자 목록을 불러오는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 관리자 생성
  Future<bool> createAdmin({
    required String name,
    required String email,
    required String password,
    required AdminRole role,
    required List<String> permissions,
  }) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보 확인
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // Firebase Auth에 사용자 생성
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 사용자 이름 업데이트
      await userCredential.user!.updateDisplayName(name);

      // Firestore에 관리자 정보 저장
      await _firestore.collection('admins').doc(uid).set({
        'email': email,
        'name': name,
        'role': adminRoleToString(role),
        'permissions': permissions,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'createdBy': _authController.currentAdmin.value!.name,
      });

      // 활동 로그 기록
      await _authController.logActivity(
        'create_admin',
        uid,
        'admin',
        {},
        {
          'name': name,
          'email': email,
          'role': adminRoleToString(role),
          'permissions': permissions,
          'isActive': true,
          'createdBy': _authController.currentAdmin.value!.name,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      // 관리자 목록 새로고침
      await loadAdmins();

      Get.snackbar(
        '관리자 생성',
        '관리자 계정이 성공적으로 생성되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('관리자 생성 오류: $e');

      String errorMessage = '관리자 생성 중 오류가 발생했습니다.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = '이미 사용 중인 이메일입니다.';
            break;
          case 'invalid-email':
            errorMessage = '올바른 이메일 형식이 아닙니다.';
            break;
          case 'weak-password':
            errorMessage = '비밀번호가 너무 약합니다.';
            break;
        }
      } else if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '관리자 생성 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 관리자 정보 업데이트
  Future<bool> updateAdmin(
    String adminId, {
    String? name,
    AdminRole? role,
    List<String>? permissions,
  }) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

      if (!doc.exists) {
        throw Exception('관리자 정보를 찾을 수 없습니다.');
      }

      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updateData = {};

      // 업데이트할 필드 설정
      if (name != null) {
        updateData['name'] = name;
      }

      if (role != null) {
        updateData['role'] = adminRoleToString(role);
      }

      if (permissions != null) {
        updateData['permissions'] = permissions;
      }

      // 변경사항이 없으면 종료
      if (updateData.isEmpty) {
        return true;
      }

      // Firestore 업데이트
      await _firestore.collection('admins').doc(adminId).update(updateData);

      // 활동 로그 기록
      Map<String, dynamic> afterData = {...beforeData, ...updateData};

      await _authController.logActivity(
        'update_admin',
        adminId,
        'admin',
        beforeData,
        afterData,
      );

      // 관리자 목록 새로고침
      await loadAdmins();

      Get.snackbar(
        '관리자 정보 업데이트',
        '관리자 정보가 성공적으로 업데이트되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.1),
      );

      return true;
    } catch (e) {
      print('관리자 정보 업데이트 오류: $e');

      String errorMessage = '관리자 정보 업데이트 중 오류가 발생했습니다.';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      Get.snackbar(
        '관리자 정보 업데이트 실패',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // 관리자 비활성화
  Future<bool> deactivateAdmin(String adminId) async {
    try {
      isLoading.value = true;

      // 현재 관리자 정보
      if (_authController.currentAdmin.value == null) {
        throw Exception('인증 정보가 없습니다.');
      }

      // 현재 데이터 가져오기 (변경 로그용)
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

      if (!doc.exists) {
        throw Exception('관리자 정보를 찾을 수 없습니다.');
      }

      Map<String, dynamic> beforeData = doc.data() as Map<String, dynamic>;

      // Firestore 업데이트
      await _firestore
          .collection('admins')
          .doc(adminId)
          .update({'isActive': false});

      Map<String, dynamic> afterData = {...beforeData, 'isActive': false};

      // 활동 로그 기록
      await _authController.logActivity(
        'deactivate_admin',
        adminId,
        'admin',
        beforeData,
        afterData,
      );

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
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

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
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

      if (!doc.exists) {
        throw Exception('관리자 정보를 찾을 수 없습니다.');
      }

      AdminModel admin = AdminModel.fromFirestore(doc);

      // Firebase Admin SDK를 통한 비밀번호 재설정 필요
      // 클라이언트에서는 직접 다른 사용자의 비밀번호를 재설정할 수 없음
      // 실제 구현에서는 Cloud Functions를 통해 처리해야 함

      // 임시 코드 - 개발 예시
      // 실제 프로덕션에서는 Firebase Functions를 사용하여 구현해야 함
      /*
      const functions = require('firebase-functions');
      const admin = require('firebase-admin');
      
      exports.resetUserPassword = functions.https.onCall(async (data, context) => {
        // 관리자 권한 확인
        if (!context.auth || !context.auth.token.admin) {
          throw new functions.https.HttpsError('permission-denied', '관리자 권한이 필요합니다.');
        }
        
        const uid = data.uid;
        const password = data.password;
        
        try {
          await admin.auth().updateUser(uid, {
            password: password,
          });
          return { success: true };
        } catch (error) {
          throw new functions.https.HttpsError('internal', error.message);
        }
      });
      */

      // 위 Cloud Functions 코드 예시가 배포되었다고 가정
      // 실제로는 Firebase Functions 호출 코드 필요
      /*
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('resetUserPassword');
      final result = await callable.call({
        'uid': adminId,
        'password': newPassword,
      });
      */

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

  // 활동 로그 조회
  Future<void> loadActivityLogs({
    String? adminId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      isLoading.value = true;

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

      List<AdminActivityLog> logs = snapshot.docs
          .map((doc) => AdminActivityLog.fromFirestore(doc))
          .toList();

      activityLogs.value = logs;
    } catch (e) {
      print('활동 로그 조회 오류: $e');
      Get.snackbar(
        '오류',
        '활동 로그를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
