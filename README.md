# EternalTalk Flutter Overlay (Groovy / Android Studio)

이 템플릿은 **Flutter 프로젝트에 바로 덮어쓰기(overlay)** 해서 사용하는 구조입니다.

## 빠른 시작
1) Flutter 기본 프로젝트 생성
```bash
flutter create eternaltalk_app
```
2) 생성한 프로젝트 폴더로 이동 후, 본 zip 파일의 내용을 **최상위에 그대로 덮어쓰기** 하세요.
3) 패키지 설치
```bash
flutter pub get
```
4) 실행 (에뮬레이터)
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```
5) 릴리즈 빌드
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.eternaltalk.com
```

## 포함 내용
- `dio` + 인터셉터로 JWT 자동 첨부
- `flutter_secure_storage`로 토큰 보관
- `go_router`로 인증 게이트/라우팅
- 최소 화면(로그인/홈) + API 호출 뼈대
- Android Groovy Gradle 플러그인 버전 명시 (루트 `android/build.gradle`)
- Android `INTERNET` 권한 추가

> 참고: 이미 `flutter create`가 생성한 Gradle 및 wrapper 구조를 사용합니다. 본 템플릿은 필요한 파일만 덮어씌웁니다.
