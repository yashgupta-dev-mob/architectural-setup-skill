import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../globals.dart';
import '../../net/client.dart';
import '../../vendor/tracker.dart';

/// SharedPreferences key holding the session token.
const String sessionTokenKey = 'session_token';

/// The session: the value is the session token, or null when signed out.
class AuthNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() {
    void onForcedSignOut() {
      if (signedOut.value) state = const AsyncData(null);
    }

    signedOut.addListener(onForcedSignOut);
    ref.onDispose(() => signedOut.removeListener(onForcedSignOut));
    return ref.read(sharedPreferencesProvider).getString(sessionTokenKey);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final body = response.data ?? const <String, dynamic>{};
      final token = body['access_token'] as String;
      final userId = body['user_id'] as String;
      await ref
          .read(sharedPreferencesProvider)
          .setString(sessionTokenKey, token);
      signedOut.value = false;
      ThirdPartyTracker.identify(userId);
      state = AsyncData(token);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(sharedPreferencesProvider).remove(sessionTokenKey);
    ThirdPartyTracker.reset();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(
  AuthNotifier.new,
);
