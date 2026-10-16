import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's SharedPreferences. `main()` overrides this with the real
/// instance; tests override it with `SharedPreferences.setMockInitialValues`.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// The app clock. Tests override it to control cache expiry.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
