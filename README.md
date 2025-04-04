# naturebasket Admin 앱 (v0.0.1)

## 주요 기능
- 네이버, 페이스북, 구글 소셜 로그인
- 전화번호 인증 로그인
- 사용자 프로필 관리 (이름, 프로필 이미지)
- 로그인 기록 관리
- 자동 로그인 및 로그아웃
- 계정 삭제 (30일 보관 정책 적용)

## 추후 변경이나 업데이트해야될것 
  - 배송정보에 기본휴무일과, 기본 출고지정보 가지고오기, (배송정보관리 페이지 만들어서 따로 관리) **
  

## 버전 히스토리
- **v0.0.5**
   - 프로덕트 리스트/카테고리별 필터기능추가해야함 **
   - 프로덕트 디테일페이지 완성해야함**
   - 메인주요지표를 데이터를 가지고 올수 있도록 해야함 **
   - 오더관련해서 구현해야함

- **v0.0.4**
   - 상품추가 필드들 추가 업데이트 완료, 

- **v0.0.0 (초기 출시)**
  - 어드민 페이지 생성 

- **v0.0.3**
   - 상품 추가, 사용자 추가, 사용자 회원가입(이건안됨) , 완료 
   - 주문수정, 주문관련 생성해야됨, 
- **v0.0.5**

  


## 파이어베이스 
   ```bash
   firebase deploy --only functions
   ```

## 설치 및 설정
1. Flutter 환경 설정  
   ```bash
   flutter pub get
   ```

## git 업로드 방법
    ```bash
    rm -rf .git  <완전초기화시사용>

    git init 

    git add .

    git commit -m "버전 1.0.0 추가"

    git branch -m main       <새롭게 할때만 해야함>

    git tag -a v1.0.0 -m "버전 1.0.0 릴리즈"

    그 태그의 이름을 v1.0.0으로 지정하며
    버전 1.0.0 릴리즈"라는 메시지를 함께 저장한다는 의미입니다

    
    git push origin main 기본 브랜치 업데이트

    git push origin --tags 태그들 모두 푸시
   ```

## 첫 commit 할때 


해결 방법
1. 먼저 GitHub에서 빈 저장소를 만든 뒤 주소를 복사해주세요.
예시 URL 형태:
   ```bash
    https://github.com/<계정명>/naturebasket_user-main.git

    2. 그 다음 로컬 저장소에서 Remote를 설정합니다.
     git remote add origin https://github.com/park1112/naturebasket_admin.git
   
    3. 이제 다시 push 해주세요.
    git push -u origin main
    이 과정 이후에는 다시 에러 없이 push 됩니다.
   ```



