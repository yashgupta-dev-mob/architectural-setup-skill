import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../globals.dart';
import '../../net/client.dart';
import '../../vendor/tracker.dart';

/// The favourites saved on the device under `favourites`:
/// `{"ids": ["<product id>", ...], "pending": <bool>}`.
class FavouritesState {
  const FavouritesState({this.ids = const [], this.pending = false});

  factory FavouritesState.fromJson(Map<String, dynamic> json) {
    return FavouritesState(
      ids: [for (final id in json['ids'] as List<dynamic>) id.toString()],
      pending: json['pending'] as bool? ?? false,
    );
  }

  final List<String> ids;

  /// The device's list has a change the server has not accepted yet.
  final bool pending;

  bool contains(String productId) => ids.contains(productId);

  Map<String, dynamic> toJson() => {'ids': ids, 'pending': pending};
}

/// Device-first favourites: every change lands on the device at once and is
/// pushed to the server in the background.
class FavouritesNotifier extends Notifier<FavouritesState> {
  static const String prefsKey = 'favourites';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  FavouritesState build() {
    Future<void>.microtask(syncOnStart);
    return _readStored();
  }

  FavouritesState _readStored() {
    final raw = _prefs.getString(prefsKey);
    if (raw == null) return const FavouritesState();
    try {
      return FavouritesState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const FavouritesState();
    }
  }

  Future<void> _save(FavouritesState value) {
    return _prefs.setString(prefsKey, jsonEncode(value.toJson()));
  }

  /// Adds or removes [productId], saves the list as pending and pushes it
  /// in the background.
  Future<void> toggle(String productId) async {
    final ids = List<String>.of(state.ids);
    final on = !ids.remove(productId);
    if (on) ids.add(productId);
    final next = FavouritesState(ids: ids, pending: true);
    state = next;
    ThirdPartyTracker.track('favourite_toggled', {
      'product_id': productId,
      'on': on,
    });
    await _save(next);
    unawaited(push());
  }

  /// Sends the device's list. On success `pending` is cleared, unless the
  /// list changed while the request was out (that change's own push clears
  /// it). On failure nothing changes: the list stays pending.
  Future<void> push() async {
    final sent = List<String>.of(state.ids);
    try {
      await putRemote(sent);
    } catch (_) {
      return;
    }
    if (!listEquals(state.ids, sent)) return;
    final next = FavouritesState(ids: state.ids, pending: false);
    state = next;
    await _save(next);
  }

  /// Pending: push the device's list. Otherwise: the server's list replaces
  /// the device's, unless a toggle happened while the request was out.
  Future<void> syncOnStart() async {
    if (state.pending) {
      await push();
      return;
    }
    final List<String> remote;
    try {
      remote = await getRemote();
    } catch (_) {
      return;
    }
    if (state.pending) return;
    final next = FavouritesState(ids: remote, pending: false);
    state = next;
    await _save(next);
  }

  @protected
  Future<void> putRemote(List<String> ids) async {
    await dio.put<void>('/me/favourites', data: {'ids': ids});
  }

  @protected
  Future<List<String>> getRemote() async {
    final response = await dio.get<Map<String, dynamic>>('/me/favourites');
    final ids = response.data!['ids'] as List<dynamic>;
    return [for (final id in ids) id.toString()];
  }
}

final favouritesProvider =
    NotifierProvider<FavouritesNotifier, FavouritesState>(
      FavouritesNotifier.new,
    );
