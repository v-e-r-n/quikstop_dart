# quikstop_dart

A unified Dart & Flutter client toolkit designed for **quikstop** Go backends.

`quikstop_dart` provides:
1. **Passwordless OTP Authentication**: `knock(email)` and `verify(email, code)`.
2. **Prebuilt Auth UI**: `QuikstopAuthCard` widget using the popular `otp_pin_field` for entering 6-digit verification codes.
3. **Automatic 401 Refresh Interceptor**: `QuikstopAuthInterceptor` for Dio that automatically catches `401 Unauthorized`, exchanges refresh tokens via `/api/v1/auth/refresh`, and transparently replays failed requests.
4. **Cross-Platform Real-time SSE**: Unified Web & Native Server-Sent Events client (`QuikstopEventClient`).

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  quikstop_dart:
    git:
      url: https://github.com/v-e-r-n/quikstop_dart.git
      ref: main
```

---

## Quick Start

### 1. Initialize the Client

```dart
import 'package:quikstop_dart/quikstop_dart.dart';

final quikstop = QuikstopClient(
  baseUrl: Uri.parse('https://api.example.com'),
);
```

Drop `QuikstopAuthCard` directly into your Login screen. It supports **email**, **phone (SMS)**, or **custom identifiers**:

```dart
// 1. Passwordless Email Sign-In
QuikstopAuthCard(
  client: quikstop.otp,
  appTitle: 'CLOCKSQUAD',
  recipientType: QuikstopRecipientType.email,
  primaryColor: const Color(0xFF10B981),
  onSuccess: (AuthTokens tokens) async {
    await myStorage.save(tokens);
    context.go('/dashboard');
  },
);

// 2. Passwordless Phone / SMS Sign-In
QuikstopAuthCard(
  client: quikstop.otp,
  appTitle: 'IZONNIT',
  recipientType: QuikstopRecipientType.phone,
  primaryColor: const Color(0xFF6366F1),
  inputHint: '+1 (555) 000-0000',
  codeLength: 6,
  onSuccess: (AuthTokens tokens) async {
    await myStorage.save(tokens);
    context.go('/dashboard');
  },
);
```

### 3. Automatic Token Refresh with Dio

Add `QuikstopAuthInterceptor` to your authenticated Dio instance:

```dart
final dio = Dio();

dio.interceptors.add(quikstop.createAuthInterceptor(
  getAccessToken: () => myStorage.getAccessToken(),
  getRefreshToken: () => myStorage.getRefreshToken(),
  onTokenRefreshed: (AuthTokens tokens) => myStorage.save(tokens),
  onLogout: () => authState.logout(),
));
```

### 4. Real-time Events Stream (SSE)

Connect across Web and Native platforms seamlessly:

```dart
final eventClient = quikstop.createEventClient(token: accessToken);

eventClient.eventStream.listen((QuikstopEvent event) {
  print('Received event: ${event.type} -> ${event.payload}');
});

// To disconnect:
eventClient.close();
```
