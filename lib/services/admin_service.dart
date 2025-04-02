// lib/services/admin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/admin_model.dart';
import '../models/admin_activity_log.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 관리자 목록 조회
  Future<List<AdminModel>> getAdmins() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('admins').orderBy('name').get();

      return snapshot.docs.map((doc) => AdminModel.fromFirestore(doc)).toList();
    } catch (e) {
      print('관리자 목록 조회 오류: $e');
      Get.snackbar(
        '오류',
        '관리자 목록을 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return [];
    }
  }

  // 관리자 상세 정보 조회
  Future<AdminModel?> getAdmin(String adminId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('admins').doc(adminId).get();

      if (!doc.exists) {
        return null;
      }

      return AdminModel.fromFirestore(doc);
    } catch (e) {
      print('관리자 정보 조회 오류: $e');
      Get.snackbar(
        '오류',
        '관리자 정보를 조회하는 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return null;
    }
  }

  // 관리자 추가
  Future<bool> addAdmin(AdminModel admin, String password) async {
    try {
      // Firebase Auth에 사용자 생성
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: admin.email,
        password: password,
      );

      // Firestore에 관리자 정보 저장
      await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .set(admin.toMap());

      return true;
    } catch (e) {
      print('관리자 추가 오류: $e');

      String errorMessage = '관리자 추가 중 오류가 발생했습니다.';

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
      }

      Get.snackbar(
        '오류',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );

      return false;
    }
  }

  // 관리자 수정
  Future<bool> updateAdmin(AdminModel admin) async {
    try {
      await _firestore
          .collection('admins')
          .doc(admin.uid)
          .update(admin.toMap());

      return true;
    } catch (e) {
      print('관리자 수정 오류: $e');
      Get.snackbar(
        '오류',
        '관리자 정보 수정 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return false;
    }
  }

  // 관리자 비활성화
  Future<bool> deactivateAdmin(String adminId) async {
    try {
      await _firestore
          .collection('admins')
          .doc(adminId)
          .update({'isActive': false});

      return true;
    } catch (e) {
      print('관리자 비활성화 오류: $e');
      Get.snackbar(
        '오류',
        '관리자 비활성화 중 문제가 발생했습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.1),
      );
      return false;
    }
  }

  // 관리자 활성화
  Future<bool> activateAdmin(String adminId) async {
    try {
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
