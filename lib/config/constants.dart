class AppConstants {
  // SharedPreferences 키
  static const String keyIsFirstRun = 'is_first_run';
  static const String keyUserData = 'user_data';

  // Firestore 컬렉션
  static const String usersCollection = 'users';

  // 오류 메시지
  static const String errorNetworkConnection = '네트워크 연결을 확인해주세요.';
  static const String errorLoginFailed = '로그인에 실패했습니다. 다시 시도해주세요.';
  static const String errorInvalidPhoneNumber = '유효하지 않은 전화번호입니다.';
  static const String errorInvalidVerificationCode = '유효하지 않은 인증 코드입니다.';

  // 성공 메시지
  static const String successLogin = '로그인에 성공했습니다.';
  static const String successProfileUpdate = '프로필이 업데이트되었습니다.';

  // 인트로 슬라이더 텍스트
  static const List<Map<String, String>> introSlides = [
    {
      'title': '다양한 로그인 방식',
      'description': '네이버, 페이스북, 전화번호를 통해 간편하게 로그인하세요.',
    },
    {
      'title': '개인 프로필 관리',
      'description': '프로필 정보를 쉽게 조회하고 수정할 수 있습니다.',
    },
    {
      'title': '간편한 인증',
      'description': '한 번 로그인하면 자동으로 로그인 상태가 유지됩니다.',
    },
  ];
}
