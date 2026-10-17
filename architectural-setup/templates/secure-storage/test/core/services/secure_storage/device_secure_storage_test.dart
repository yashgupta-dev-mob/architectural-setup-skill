import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template_app/core/services/pref_utils.dart';
import 'package:template_app/core/services/secure_storage/device_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PrefUtils prefs;

  setUp(() async {
    DeviceSecureStorage.resetMemory();
    SharedPreferences.setMockInitialValues({});
    prefs = PrefUtils();
    await prefs.init();
    await prefs.clearAll();
  });

  test('writes, reads and deletes on the platform', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = DeviceSecureStorage();

    await storage.write('k', 'v');
    DeviceSecureStorage.resetMemory();
    expect(await storage.read('k'), 'v');

    await storage.delete('k');
    DeviceSecureStorage.resetMemory();
    expect(await storage.read('k'), isNull);
  });

  test('instances share what is held in memory', () async {
    FlutterSecureStorage.setMockInitialValues({});

    await DeviceSecureStorage().write('k', 'v');

    expect(await DeviceSecureStorage().read('k'), 'v');
  });

  test('a fresh install wipes what a previous install left', () async {
    FlutterSecureStorage.setMockInitialValues({'auth.access_token': 'old'});

    await DeviceSecureStorage.init(prefs: prefs);

    expect(await DeviceSecureStorage().read('auth.access_token'), isNull);
    expect(prefs.getBool(key: DeviceSecureStorage.installedKey), isTrue);
  });

  test('a later start keeps the stored values', () async {
    FlutterSecureStorage.setMockInitialValues({'auth.access_token': 'kept'});
    await prefs.setBool(key: DeviceSecureStorage.installedKey, value: true);

    await DeviceSecureStorage.init(prefs: prefs);

    expect(await DeviceSecureStorage().read('auth.access_token'), 'kept');
  });
}
