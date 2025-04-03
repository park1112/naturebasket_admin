// lib/models/admin_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// 관리자 권한 수준 정의
enum AdminRole {
  superAdmin, // 모든 권한
  manager, // 일반 관리자 (일부 설정 제외)
  editor, // 컨텐츠 편집 권한
  viewer // 조회만 가능
}

// AdminRole enum을 String으로 변환
String adminRoleToString(AdminRole role) {
  switch (role) {
    case AdminRole.superAdmin:
      return 'superAdmin';
    case AdminRole.manager:
      return 'manager';
    case AdminRole.editor:
      return 'editor';
    case AdminRole.viewer:
      return 'viewer';
    default:
      return 'viewer';
  }
}

// String을 AdminRole로 변환
AdminRole stringToAdminRole(String role) {
  switch (role) {
    case 'superAdmin':
      return AdminRole.superAdmin;
    case 'manager':
      return AdminRole.manager;
    case 'editor':
      return AdminRole.editor;
    case 'viewer':
      return AdminRole.viewer;
    default:
      return AdminRole.viewer;
  }
}

class AdminModel {
  final String uid;
  final String email;
  final String name;
  final String? photoURL;
  final AdminRole role;
  final bool isActive;
  final List<String> permissions; // 세부 권한 항목들
  final DateTime createdAt;
  final DateTime lastLogin;
  final String createdBy;

  AdminModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoURL,
    required this.role,
    this.isActive = true,
    required this.permissions,
    required this.createdAt,
    required this.lastLogin,
    required this.createdBy,
  });

  // Firestore에서 데이터 로드
  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      photoURL: data['photoURL'],
      role: stringToAdminRole(data['role'] ?? 'viewer'),
      isActive: data['isActive'] ?? true,
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
    );
  }

  // Firestore에 저장하기 위한 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'role': adminRoleToString(role),
      'isActive': isActive,
      'permissions': permissions,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'createdBy': createdBy,
    };
  }

  // 값 복사 및 수정
  AdminModel copyWith({
    String? name,
    String? photoURL,
    AdminRole? role,
    bool? isActive,
    List<String>? permissions,
    DateTime? lastLogin,
  }) {
    return AdminModel(
      uid: this.uid,
      email: this.email,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      permissions: permissions ?? this.permissions,
      createdAt: this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      createdBy: this.createdBy,
    );
  }
}
