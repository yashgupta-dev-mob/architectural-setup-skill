import 'package:flutter_test/flutter_test.dart';
import 'package:mymali/core/services/pref_utils.dart';
import 'package:mymali/core/services/secure_storage/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fake_secure_storage.dart';

void main() {
  const url = 'https://abcd1234.supabase.co';
  const key = 'sb-abcd1234-auth-token';

  late FakeSecureStorage secure;
  late SecureSessionStorage storage;
  late PrefUtils prefUtils;

  Future<void> build(Map<String, String> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    prefUtils = PrefUtils();
    await prefUtils.init();
    await prefUtils.clearAll();
    for (final entry in prefs.entries) {
      await prefUtils.setString(key: entry.key, value: entry.value);
    }
    secure = FakeSecureStorage();
    storage = SecureSessionStorage(
      storage: secure,
      prefs: prefUtils,
      supabaseUrl: url,
    );
  }

  test('uses the SDK key for the project', () {
    expect(SecureSessionStorage.keyFor(url), key);
  });

  test('persists, reads and removes the session securely', () async {
    await build({});
    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
    await storage.persistSession('{"session":1}');
    expect(secure.values[key], '{"session":1}');
    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), '{"session":1}');

    await storage.removePersistedSession();
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('moves a session the SDK saved in prefs', () async {
    await build({key: '{"old":1}'});

    await storage.initialize();

    expect(await storage.accessToken(), '{"old":1}');
    expect(prefUtils.getString(key: key), isNull);
  });

  test('a newer secure session wins over the prefs copy', () async {
    await build({key: '{"old":1}'});
    secure.values[key] = '{"new":1}';

    await storage.initialize();

    expect(await storage.accessToken(), '{"new":1}');
    expect(prefUtils.getString(key: key), isNull);
  });
}
