# The app shell, in MyMali's shape

These files are per app: write them for the app being migrated, in this
shape, keeping the app's own start-up order, first screen and navigation.

## `lib/main.dart`
```dart
import 'app/bootstrap.dart';

void main() {
  bootstrap();
}
```

## `lib/app/bootstrap.dart`
Everything the old `main()` awaited before `runApp`, in the same order,
plus what the architecture needs: `Env.load()`, the `init()` of each
installed storage module, and `configureDependencies()`. Add nothing else
(MyMali's portrait lock, Firebase, Supabase are MyMali's own).
```dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  // The app's own awaited start-up work, in its original order, e.g.:
  // await PrefUtils().init();            // prefs module
  // await DeviceSecureStorage.init();    // secure-storage module
  // await HiveLocalCache.init();         // local-cache module
  configureDependencies();
  // One AuthBloc for the app and the router redirect (composition code).
  final authBloc = sl<AuthBloc>()..add(AuthStatusRequested());
  runApp(
    App(authBloc: authBloc, router: AppRouter(authBloc: authBloc).router),
  );
}
```
If the old app awaited nothing before its first frame and its first screen
depended on a value read later (a token read asynchronously), keep that
timing: read it in the bloc's start event, not in `bootstrap()`.

## `lib/app/app.dart`
```dart
class App extends StatelessWidget {
  const App({super.key, required this.router, required this.authBloc});

  final GoRouter router;

  /// The one app-wide AuthBloc, also given to [AppRouter].
  final AuthBloc authBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // App-wide blocs only; screen blocs are provided by their pages.
        // Created in bootstrap(), because the router's redirect needs it too.
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: '<the app title, unchanged>',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,           // only if the app had one
          themeMode: ThemeMode.light,         // the app's own rule
          routerConfig: router,
        ),
      ),
    );
  }
}
```
Cross-feature reactions (sign-out clears a list, sign-in starts a sync)
are `BlocListener`s here, with a precise `listenWhen`.

## `lib/core/router/app_routes.dart`
```dart
/// Single source of truth for route names and paths.
enum AppRoute {
  login('/login'),
  notes('/'),
  settings('/settings'),
  /// One note; pass its id as the `id` path parameter.
  noteDetail('/notes/:id');

  const AppRoute(this.path);

  final String path;
}
```

## `lib/core/router/navigator_keys.dart`
```dart
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
```

## `lib/core/router/app_router.dart`
```dart
class AppRouter {
  AppRouter({this.authBloc});

  final AuthBloc? authBloc;

  late final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoute.notes.path,
    // A redirect only when the app had one (signed out → login, …), with
    // the same rule; refreshListenable for whatever triggered it.
    routes: [
      GoRoute(
        path: AppRoute.login.path,
        name: AppRoute.login.name,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoute.notes.path,
        name: AppRoute.notes.name,
        builder: (context, state) => const NotesPage(),
      ),
    ],
  );
}
```
An app that swapped its home widget in place (no route change) keeps that
feel: a redirect to the same two locations replaces the page without a back
stack. An app with bottom tabs whose tabs kept their state uses
`StatefulShellRoute.indexedStack` (one
branch and navigator key per tab, as MyMali does); tabs that were rebuilt
on every switch use a plain `ShellRoute`.

## `lib/core/di/injection_container.dart`
```dart
final GetIt sl = GetIt.instance;

void configureDependencies() {
  _registerCore();
  _registerAuthData();
  registerAuthFeature();
  _registerNotesData();
  registerNotesFeature();
}

void _registerCore() {
  sl
    ..registerLazySingleton<PrefUtils>(PrefUtils.new)
    ..registerLazySingleton<SecureStorage>(DeviceSecureStorage.new)
    ..registerLazySingleton<Networking>(
      () => NetworkingService(secureStorage: sl()),
    );
}

void _registerNotesData() {
  sl
    ..registerLazySingleton<NotesRemoteDataSource>(
      () => NotesRemoteDataSourceImpl(networking: sl()),
    )
    ..registerLazySingleton<NotesRepository>(
      () => NotesRepositoryImpl(remote: sl()),
    );
}

/// The notes screens' use cases and bloc. They depend only on
/// [NotesRepository], so tests can register a fake one and call this.
void registerNotesFeature() {
  sl
    ..registerLazySingleton(() => GetNotes(sl()))
    ..registerLazySingleton(() => DeleteNote(sl()))
    ..registerFactory(() => NotesBloc(getNotes: sl(), deleteNote: sl()));
}
```

## `.env` / `.env.example`
Every URL, key and id the old code hardcoded moves here, with the same
value; `.env` is listed under `flutter: assets:` in `pubspec.yaml` and in
`.gitignore`, `.env.example` holds placeholders. Tests call
`dotenv.testLoad(fileInput: …)` when they need `Env`.

## A whole feature
`reference/support_feature/` is one complete MyMali feature with its tests
(remote and local data sources, model, repository, both use cases, bloc
with `isStale`, page, header wrapping `PageHeader`, texts helper). It is
**cache-first**; a network-only feature has the same shape without the
local data source, the `GetCached…` use case and the `isStale` /
`isRefreshing` fields. Read it for shape only: its content is MyMali's.
