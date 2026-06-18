## 1.1.1

- Bump native CallKit dependencies to 4.23.0 (Android `chat-call-kit` and iOS `EaseCallUIKit`).

## 1.1.0

- **Breaking change**: Remove `setCurrentUserInfo` from Dart layer.
- Android: Add default `CallInfoProvider` that fetches user avatar and nickname from Hyphenate `EMUserInfoManager` automatically.
- iOS: Add default `CallUserProfileProvider` that fetches user avatar and nickname from Hyphenate `EMUserInfoManager` automatically.
- User and group profiles are now resolved natively without requiring Flutter to pass them explicitly.

## 1.0.1

- Remove hardcoded AppKey from example.

## 1.0.0

- Initial release.
- Support iOS CallKit via `EaseCallUIKit`.
- Support Android CallKit via `chat-call-kit`.
- Provide Dart APIs: `initIM`, `initCallKit`, `login`, `loginWithPassword`, `logout`, `startSingleCall`, `startGroupCall`.
- Provide call event stream: `onReceivedCall`, `onEndCallWithReason`, `onCallError`, `onRemoteUserJoined`, `onRemoteUserLeft`.
