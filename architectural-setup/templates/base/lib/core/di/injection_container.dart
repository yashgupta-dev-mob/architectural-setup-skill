// GENERIC: per app. The source app's container shape: _registerCore, then _register<X>Data + register<X>Feature per feature.
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

/// Called once by `bootstrap()`, after `Env.load()` and any other awaited
/// start-up work the app had.
void configureDependencies() {
  _registerCore();
}

/// Core services: `Networking`, and the storage services the app uses.
void _registerCore() {}
