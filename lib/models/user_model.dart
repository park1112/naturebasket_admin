import 'package:cloud_firestore/cloud_firestore.dart';

enum LoginType { naver, facebook, phone, unknown, google }

class UserModel {
  final String uid;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? photoURL;
  final LoginType loginType;
  final DateTime lastLogin;
  final List<Map<String, dynamic>> loginHistory; // 로그인 기록 추가
  final List<Map<String, dynamic>> signInHistory; // 로그인 기록 추가

  UserModel({
    required this.uid,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoURL,
    required this.loginType,
    required this.lastLogin,
    this.loginHistory = const [], // 기본값 빈 배열
    this.signInHistory = const [], // 기본값 빈 배열
  });
  static void debugPrintFirestoreData(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    print('===== Firestore User Data =====');
    print('ID: ${doc.id}');
    data.forEach((key, value) {
      print('$key: $value (${value.runtimeType})');
      if (key == 'loginHistory' && value is List) {
        print('--- Login History Details ---');
        int index = 0;
        for (var item in value) {
          print('Item $index:');
          if (item is Map) {
            item.forEach((k, v) {
              print('  $k: $v (${v.runtimeType})');
            });
          } else {
            print('  Item format: ${item.runtimeType}');
          }
          index++;
        }
      }
    });
    print('===============================');
  }

  // 파이어스토어에서 데이터 로드
  // 파이어스토어에서 데이터 로드
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    debugPrintFirestoreData(doc);
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // lastLogin 필드 안전하게 처리
    DateTime lastLogin;
    if (data['lastLogin'] == null) {
      lastLogin = DateTime.now();
    } else if (data['lastLogin'] is Timestamp) {
      lastLogin = (data['lastLogin'] as Timestamp).toDate();
    } else if (data['lastLogin'] is String) {
      try {
        lastLogin = DateTime.parse(data['lastLogin'] as String);
      } catch (e) {
        lastLogin = DateTime.now();
      }
    } else {
      lastLogin = DateTime.now();
    }

    // loginHistory 필드 처리
    List<Map<String, dynamic>> loginHistory = [];
    if (data['loginHistory'] != null && data['loginHistory'] is List) {
      try {
        List<dynamic> rawHistory = data['loginHistory'] as List;
        print('Login history raw length: ${rawHistory.length}');

        // 각 항목 개별적으로 변환
        for (var item in rawHistory) {
          if (item is Map) {
            try {
              // timestamp 처리
              dynamic rawTimestamp = item['timestamp'];
              DateTime timestamp;

              if (rawTimestamp is Timestamp) {
                timestamp = rawTimestamp.toDate();
              } else if (rawTimestamp is String) {
                try {
                  timestamp = DateTime.parse(rawTimestamp);
                } catch (e) {
                  print('String parsing error: $e');
                  timestamp = DateTime.now();
                }
              } else {
                print('Unknown timestamp type: ${rawTimestamp.runtimeType}');
                timestamp = DateTime.now();
              }

              // loginType 처리
              String loginType = 'unknown';
              if (item['loginType'] is String) {
                loginType = item['loginType'];
              }

              // 유효한 항목 추가
              loginHistory.add({
                'timestamp': timestamp,
                'loginType': loginType,
              });

              print(
                  'Added history item: timestamp=${timestamp}, loginType=${loginType}');
            } catch (e) {
              print('Error processing history item: $e');
            }
          }
        }

        print('Final processed login history count: ${loginHistory.length}');
      } catch (e) {
        print('Error parsing login history: $e');
        loginHistory = [];
      }
    }

    return UserModel(
      uid: doc.id,
      name: data['name'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      loginType: LoginType.values.firstWhere(
        (type) => type.toString().split('.').last == data['loginType'],
        orElse: () => LoginType.unknown,
      ),
      lastLogin: lastLogin,
      loginHistory: loginHistory,
    );
  }

  // Map으로 변환 (Firestore에 저장용)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'loginType': loginType.toString().split('.').last,
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  // JSON으로 변환 (SharedPreferences 저장용)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'loginType': loginType.toString().split('.').last,
      'lastLogin': lastLogin.toIso8601String(),
      'loginHistory': loginHistory
          .map((log) => {
                'timestamp': log['timestamp'].toIso8601String(),
                'loginType': log['loginType'],
              })
          .toList(),
    };
  }

  // JSON에서 객체 생성 (SharedPreferences에서 로드)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> loginHistory = [];
    if (json['loginHistory'] != null) {
      loginHistory = List<Map<String, dynamic>>.from(
          (json['loginHistory'] as List).map((item) => {
                'timestamp': DateTime.parse(item['timestamp']),
                'loginType': item['loginType'],
              }));
    }

    return UserModel(
      uid: json['uid'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      loginType: LoginType.values.firstWhere(
        (type) => type.toString().split('.').last == json['loginType'],
        orElse: () => LoginType.unknown,
      ),
      lastLogin: DateTime.parse(json['lastLogin']),
      loginHistory: loginHistory,
    );
  }

  // 복사 및 업데이트
  UserModel copyWith({
    String? name,
    String? photoURL,
  }) {
    return UserModel(
      uid: this.uid,
      name: name ?? this.name,
      email: this.email,
      phoneNumber: this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      loginType: this.loginType,
      lastLogin: DateTime.now(),
      loginHistory: this.loginHistory,
    );
  }
}
