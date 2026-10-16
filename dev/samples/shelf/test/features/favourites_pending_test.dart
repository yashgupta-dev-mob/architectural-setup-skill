import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelf/features/favourites/favourites_provider.dart';
import 'package:shelf/globals.dart';

/// The real notifier with the two network calls replaced by completers the
/// test controls.
class FakeFavouritesNotifier extends FavouritesNotifier {
  final List<List<String>> puts = [];
  final List<Completer<void>> putCompleters = [];
  final Completer<List<String>> getCompleter = Completer<List<String>>();
  int gets = 0;

  @override
  Future<void> putRemote(List<String> ids) {
    puts.add(List<String>.of(ids));
    final completer = Completer<void>();
    putCompleters.add(completer);
    return completer.future;
  }

  @override
  Future<List<String>> getRemote() {
    gets++;
    return getCompleter.future;
  }
}

Future<SharedPreferences> prefsWith(Map<String, Object> values) {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

String stored(List<String> ids, {required bool pending}) {
  return jsonEncode({'ids': ids, 'pending': pending});
}

Map<String, dynamic> savedFavourites(SharedPreferences prefs) {
  return jsonDecode(prefs.getString(FavouritesNotifier.prefsKey)!)
      as Map<String, dynamic>;
}

DioException offline() {
  return DioException(
    requestOptions: RequestOptions(path: '/me/favourites'),
    type: DioExceptionType.connectionError,
    message: 'offline',
  );
}

ProviderContainer makeContainer(
  SharedPreferences prefs,
  FakeFavouritesNotifier fake,
) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWith((ref) => prefs),
      favouritesProvider.overrideWith(() => fake),
    ],
  );
  addTearDown(container.dispose);
  container.listen(favouritesProvider, (_, _) {});
  return container;
}

void main() {
  group('toggle', () {
    test(
      'updates the list at once, saves it as pending and starts a PUT',
      () async {
        final prefs = await prefsWith({});
        final fake = FakeFavouritesNotifier();
        final container = makeContainer(prefs, fake);
        fake.getCompleter.complete(const []);
        await pumpEventQueue();

        await container.read(favouritesProvider.notifier).toggle('p1');

        final state = container.read(favouritesProvider);
        expect(state.ids, ['p1']);
        expect(state.pending, isTrue);
        expect(savedFavourites(prefs), {
          'ids': ['p1'],
          'pending': true,
        });
        expect(fake.puts, [
          ['p1'],
        ]);
      },
    );

    test('a successful push clears pending on the device', () async {
      final prefs = await prefsWith({});
      final fake = FakeFavouritesNotifier();
      final container = makeContainer(prefs, fake);
      fake.getCompleter.complete(const []);
      await pumpEventQueue();
      await container.read(favouritesProvider.notifier).toggle('p1');

      fake.putCompleters.single.complete();
      await pumpEventQueue();

      final state = container.read(favouritesProvider);
      expect(state.ids, ['p1']);
      expect(state.pending, isFalse);
      expect(savedFavourites(prefs), {
        'ids': ['p1'],
        'pending': false,
      });
    });

    test('a failed push keeps the list pending, silently', () async {
      final prefs = await prefsWith({});
      final fake = FakeFavouritesNotifier();
      final container = makeContainer(prefs, fake);
      fake.getCompleter.complete(const []);
      await pumpEventQueue();
      await container.read(favouritesProvider.notifier).toggle('p1');

      fake.putCompleters.single.completeError(offline());
      await pumpEventQueue();

      final state = container.read(favouritesProvider);
      expect(state.ids, ['p1']);
      expect(state.pending, isTrue);
      expect(savedFavourites(prefs), {
        'ids': ['p1'],
        'pending': true,
      });
    });

    test('toggling again removes the id; a push that completes after a later '
        'toggle leaves pending set', () async {
      final prefs = await prefsWith({});
      final fake = FakeFavouritesNotifier();
      final container = makeContainer(prefs, fake);
      fake.getCompleter.complete(const []);
      await pumpEventQueue();
      final notifier = container.read(favouritesProvider.notifier);

      await notifier.toggle('p1');
      await notifier.toggle('p2');
      await notifier.toggle('p1');
      expect(container.read(favouritesProvider).ids, ['p2']);
      expect(fake.puts, [
        ['p1'],
        ['p1', 'p2'],
        ['p2'],
      ]);

      fake.putCompleters[0].complete();
      await pumpEventQueue();
      expect(container.read(favouritesProvider).pending, isTrue);

      fake.putCompleters[2].complete();
      await pumpEventQueue();
      expect(container.read(favouritesProvider).pending, isFalse);
      expect(savedFavourites(prefs), {
        'ids': ['p2'],
        'pending': false,
      });
    });
  });

  group('start-up sync', () {
    test(
      'with pending set, the device list is pushed and nothing is fetched',
      () async {
        final prefs = await prefsWith({
          FavouritesNotifier.prefsKey: stored(['a', 'b'], pending: true),
        });
        final fake = FakeFavouritesNotifier();
        final container = makeContainer(prefs, fake);

        expect(container.read(favouritesProvider).ids, ['a', 'b']);
        await pumpEventQueue();
        expect(fake.gets, 0);
        expect(fake.puts, [
          ['a', 'b'],
        ]);

        fake.putCompleters.single.complete();
        await pumpEventQueue();
        expect(container.read(favouritesProvider).pending, isFalse);
        expect(savedFavourites(prefs), {
          'ids': ['a', 'b'],
          'pending': false,
        });
      },
    );

    test('without pending, the server list replaces the device copy', () async {
      final prefs = await prefsWith({
        FavouritesNotifier.prefsKey: stored(['a'], pending: false),
      });
      final fake = FakeFavouritesNotifier();
      final container = makeContainer(prefs, fake);
      await pumpEventQueue();
      expect(fake.gets, 1);
      expect(fake.puts, isEmpty);

      fake.getCompleter.complete(['z', 'y']);
      await pumpEventQueue();

      final state = container.read(favouritesProvider);
      expect(state.ids, ['z', 'y']);
      expect(state.pending, isFalse);
      expect(savedFavourites(prefs), {
        'ids': ['z', 'y'],
        'pending': false,
      });
    });

    test(
      'a toggle made while the fetch is out is not undone by its result',
      () async {
        final prefs = await prefsWith({
          FavouritesNotifier.prefsKey: stored(['a'], pending: false),
        });
        final fake = FakeFavouritesNotifier();
        final container = makeContainer(prefs, fake);
        await pumpEventQueue();

        await container.read(favouritesProvider.notifier).toggle('p1');
        fake.getCompleter.complete(['z']);
        await pumpEventQueue();

        final state = container.read(favouritesProvider);
        expect(state.ids, ['a', 'p1']);
        expect(state.pending, isTrue);
      },
    );

    test('a failed fetch keeps the device copy', () async {
      final prefs = await prefsWith({
        FavouritesNotifier.prefsKey: stored(['a'], pending: false),
      });
      final fake = FakeFavouritesNotifier();
      final container = makeContainer(prefs, fake);
      await pumpEventQueue();

      fake.getCompleter.completeError(offline());
      await pumpEventQueue();

      final state = container.read(favouritesProvider);
      expect(state.ids, ['a']);
      expect(state.pending, isFalse);
      expect(
        prefs.getString(FavouritesNotifier.prefsKey),
        stored(['a'], pending: false),
      );
    });
  });
}
