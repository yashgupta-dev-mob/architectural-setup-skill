# fieldnotes — behaviour manifest

Every numbered entry is an observable behaviour of this app that must survive
a restructuring. "Toast" means `Fluttertoast.showToast(msg: …)` with the
plugin's default length and gravity. `{baseUrl}` is
`https://api.fieldnotes.example.com`.

Verified on Flutter 3.47.5 / Dart 3.13.4: `flutter analyze` → "No issues
found!", `flutter test` → 12 tests pass.

## Startup and navigation

- **B1.** `main()` calls `runApp(const FieldNotesApp())`. Nothing asynchronous
  runs before the first frame (no splash, no awaited initialisation).
- **B2.** The root is `MaterialApp(title: 'Field notes')`. Its `home` is
  `NotesScreen` when `AuthProvider.isLoggedIn` is true (a token is held in
  memory) and `LoginScreen` otherwise. The home widget is swapped in place
  whenever `isLoggedIn` changes (login, logout, unauthorized); nothing is
  pushed or popped for that switch, and routes pushed on top (Settings, New
  note) are not affected.
- **B3.** `isLoggedIn` is false until the stored token has been read
  asynchronously from SharedPreferences, so on a cold start with a saved
  token the login screen can be visible for a frame before the notes screen
  replaces it.
- **B4.** All navigation is `Navigator.push(context, MaterialPageRoute(...))`:
  notes → Settings, notes → New note. The system/AppBar back button pops.
  New note pops itself (`Navigator.pop`) after a successful save. There are
  no named routes.

## Theme

- **B5.** Light theme `ThemeData(primarySwatch: Colors.teal, useMaterial3:
  true)`; dark theme `ThemeData.dark()`. `themeMode` is `ThemeMode.dark` when
  `SettingsProvider.isDark` is true, otherwise `ThemeMode.light`.
  `ThemeMode.system` is never used, so the phone's setting is ignored.
- **B6.** `isDark` is read asynchronously from SharedPreferences key
  `dark_mode` (bool, default `false`) when `SettingsProvider` is created, so
  the very first frame is light even when dark mode was saved.
- **B7.** Colours hardcoded in widgets, identical in both themes: every
  `AppBar` has `backgroundColor: Colors.teal` and `foregroundColor:
  Colors.white`; the notes FAB and the New note "Save" button are
  `Color(0xFF00695C)` with white icon/text; the load-error text and the
  swipe-to-delete background are `Colors.redAccent` (white bin icon on the
  latter); the email hint, the body hint, "No notes yet", the date on each
  note row and the version number are `Colors.grey`; the login progress bar
  and the dark-mode switch thumb (`activeThumbColor`) are `Colors.teal`.

## Network — `ApiService` (lib/services/api_service.dart)

- **B8.** `static const String baseUrl =
  'https://api.fieldnotes.example.com'`. All requests go through one
  `package:http` `Client` (`ApiService({http.Client? client})`, default
  `http.Client()`). There is no caching, no retry, no interceptor, no
  logging and no auth refresh.
- **B9.** Every request has `.timeout(const Duration(seconds: 10))`. A
  `TimeoutException` becomes `ApiException(0, 'Request timed out')`; an
  `http.ClientException` (no connection, DNS failure, connection reset)
  becomes `ApiException(0, 'Network error')`. Any other exception propagates
  unchanged.
- **B10.** `ApiException(int statusCode, String message)` with
  `toString()` → `ApiException(<statusCode>): <message>`.
  `UnauthorizedException()` with `toString()` → `UnauthorizedException`.
  Both `implements Exception`.
- **B11.** Error message rule for every non-success status: the body's
  `error` value when the body is a JSON object whose `error` is a string;
  otherwise (no `error`, non-string `error`, non-JSON body such as an HTML
  error page) the method's fallback text named below.
- **B12.** `login(email, password)` → `POST {baseUrl}/v1/auth/login`, header
  `Content-Type: application/json` (package:http appends `; charset=utf-8`
  on the wire), body `{"email": <email>, "password": <password>}`.
  200 → returns `body['token']` as `String`. Any other status →
  `ApiException(status, error ?? 'Login failed')`. A 200 whose body is not a
  JSON object with a string `token` throws a `FormatException`/`TypeError`,
  not an `ApiException`.
- **B13.** `fetchNotes(token)` → `GET {baseUrl}/v1/notes`, headers
  `Authorization: Bearer <token>` and `Accept: application/json`, no body.
  200 → `List<Note>` built from `body['notes']` with `Note.fromJson` on each
  element, in server order; a missing or `null` `notes` gives an empty list.
  401 → throws `UnauthorizedException`. Any other status →
  `ApiException(status, error ?? 'Failed to fetch notes')`.
- **B14.** `createNote(token, title, body)` → `POST {baseUrl}/v1/notes`,
  headers `Authorization: Bearer <token>`, `Content-Type: application/json`,
  `Accept: application/json`, body `{"title": <title>, "body": <body>}`.
  201 → `Note.fromJson(body)`. Any other status, **including 200 and 401**, →
  `ApiException(status, error ?? 'Failed to create note')` (a 401 here is an
  `ApiException`, never an `UnauthorizedException`).
- **B15.** `deleteNote(token, id)` → `DELETE {baseUrl}/v1/notes/<id>` (the id
  is interpolated as-is, not URL-encoded), headers `Authorization: Bearer
  <token>` and `Accept: application/json`, no body. Success **only** on 204;
  every other status, including 200 with a body and 401, →
  `ApiException(status, error ?? 'Failed to delete note')`.

## Model — `Note` (lib/models/note.dart)

- **B16.** `Note({required String id, required String title, required String
  body, required DateTime createdAt})`, immutable, no equality override.
  `Note.fromJson` reads `id`, `title`, `body` (all required strings; a
  missing one throws) and `created_at` (ISO-8601 string via
  `DateTime.parse`). `toJson()` writes exactly the four keys `id`, `title`,
  `body`, `created_at` with `createdAt.toIso8601String()`. `fromJson →
  toJson` reproduces the original map for a UTC timestamp with millisecond
  precision, e.g. `2024-03-05T09:15:30.000Z`.

## Authentication — `AuthProvider` (lib/providers/auth_provider.dart)

- **B17.** Persistence: SharedPreferences key `auth_token` (String). It is
  read once when the provider is constructed; when the read completes
  `token`/`isLoggedIn` are set and listeners are notified. `isLoading`
  starts false.
- **B18.** `login(email, password)`: sets `isLoading = true` and notifies;
  awaits `ApiService.login`; on success writes `auth_token`, then sets
  `token`; in `finally` sets `isLoading = false` and notifies (so a single
  notification carries both the token and the end of loading). On any
  exception the token is unchanged, `isLoading` is reset, and the exception
  propagates to the caller.
- **B19.** `logout()`: removes `auth_token` from SharedPreferences, sets
  `token = null`, notifies. `handleUnauthorized()` simply calls `logout()`.
  Nothing else is cleared from storage on logout (`dark_mode` survives).

## Notes — `NotesProvider` (lib/providers/notes_provider.dart)

- **B20.** State: `notes` (an unmodifiable snapshot of the list, server
  order), `isLoading` (initially false), `error` (initially null).
  Constructor `NotesProvider({ApiService? api, VoidCallback?
  onUnauthorized})`; the app wires `onUnauthorized` to
  `AuthProvider.handleUnauthorized()`.
- **B21.** `load(token)` always hits the network: there is no cache, no
  freshness check and no in-flight guard (two concurrent calls make two
  requests; the last to finish wins). It sets `isLoading = true`, `error =
  null` and notifies; then on success replaces `notes` with the server's
  list; on `UnauthorizedException` sets `notes = []` and calls
  `onUnauthorized` (error stays null); on `ApiException` (any status, timeout
  or network error) sets `error = 'Could not load notes'` and **keeps the
  previous `notes`**; in `finally` sets `isLoading = false` and notifies. Any
  other exception type propagates after the `finally`.
- **B22.** `add(token, title, body)`: awaits `createNote`, inserts the
  returned note at index 0 (top of the list) and notifies once. On failure
  the list is unchanged and the exception propagates to the caller.
- **B23.** `remove(token, id)` is optimistic. If no note has that id it
  returns at once without a request or a notification. Otherwise it removes
  the note from the list and notifies **before** calling `deleteNote`. On
  success nothing more happens (one notification in total). On **any**
  exception the note is re-inserted at its original index (or at the end if
  the list has meanwhile become shorter than that index), listeners are
  notified a second time, and the exception is rethrown.
- **B24.** `clear()` sets `notes = []`, `error = null` and notifies. The
  notes screen calls it from the logout button before `AuthProvider.logout()`,
  so the next signed-in user never sees the previous user's notes.

## Settings — `SettingsProvider` (lib/providers/settings_provider.dart)

- **B25.** Persistence key `dark_mode` (bool). Read at construction (default
  false) and then notifies. `setDark(value)` updates `isDark` and notifies
  immediately, and only then writes `dark_mode` to SharedPreferences.

## Login screen (lib/screens/login_screen.dart)

- **B26.** AppBar title `Field notes`. Two raw `TextField`s: email (label
  `Email`, hint `you@example.com` in grey, `keyboardType:
  TextInputType.emailAddress`) and password (label `Password`,
  `obscureText: true`). No validation messages are shown on this screen.
- **B27.** A full-width `ElevatedButton` labelled `Sign in` is enabled only
  while `AuthProvider.isLoading` is false **and** both fields contain text
  (raw text; a field holding only spaces counts as filled). While
  `isLoading`, a teal `LinearProgressIndicator` appears directly above the
  button and the button is disabled; its label stays `Sign in`.
- **B28.** Pressing Sign in calls `AuthProvider.login(email.trim(),
  password)` (the password is sent untrimmed). Success → toast
  `Welcome back` (shown after the token has been stored) and the home
  switches to the notes screen (B2). `ApiException` → toast with
  `exception.message`: the server's `error` string, or `Login failed`,
  `Request timed out` or `Network error`. Other exception types are not
  caught. The typed text stays in both fields after a failure.

## Notes screen (lib/screens/notes_screen.dart)

- **B29.** AppBar title `Field notes` with two actions, in order: a settings
  `IconButton` (`Icons.settings`, tooltip `Settings`) that pushes
  `SettingsScreen`, and a logout `IconButton` (`Icons.logout`, tooltip
  `Log out`) that calls `NotesProvider.clear()` and then
  `AuthProvider.logout()`, after which the home becomes the login screen.
- **B30.** `NotesProvider.load(token)` is called once right after the
  screen's first frame (post-frame callback), on every pull-to-refresh
  (`RefreshIndicator`, whose spinner stays until the load completes) and on
  Retry. Pull-to-refresh works in every state (list, loading, empty, error)
  because each body is an always-scrollable scroll view.
- **B31.** Body, by priority: (1) `error != null` → centred `Text(error)` in
  `Colors.redAccent` with a `TextButton` labelled `Retry` below it, shown
  even if notes are still held in the provider; (2) `isLoading &&
  notes.isEmpty` → centred `CircularProgressIndicator`; (3) `notes.isEmpty`
  → centred grey `Text('No notes yet')`; (4) otherwise the list. Consequence
  of (1): after a failed refresh the error view replaces the list until the
  next `load` succeeds, even if a note is added in the meantime.
- **B32.** The list is a `ListView.builder` of one `Dismissible` per note,
  keyed `ValueKey(note.id)`, `direction: DismissDirection.endToStart` (swipe
  right-to-left only), background `Colors.redAccent` with a white
  `Icons.delete` aligned to the right. Its child is a `ListTile`: title =
  `note.title`; subtitle = `note.body`, at most 2 lines with ellipsis;
  trailing = `createdAt.toLocal()` formatted `dd/MM/yyyy` (zero-padded) in
  grey at font size 12. Tapping a row does nothing.
- **B33.** Swiping a row away calls `NotesProvider.remove(token, note.id)`:
  the row leaves the list immediately (B23). When the server answers 204 →
  toast `Note deleted`. On any failure (non-204 status, timeout, network
  error) → toast `Could not delete note` and the row reappears at its
  original position. A 401 on delete does **not** log the user out.
- **B34.** A `FloatingActionButton` (`Icons.add`, tooltip `New note`,
  background `Color(0xFF00695C)`, white icon) pushes `NewNoteScreen`.
- **B35.** Unauthorized flow: a 401 from `fetchNotes` empties the notes,
  calls `AuthProvider.handleUnauthorized()` → `logout()`, the stored token is
  removed and the home switches to the login screen. No toast, snackbar or
  dialog is shown.

## New note screen (lib/screens/new_note_screen.dart)

- **B36.** AppBar title `New note`. Raw `TextField` for the title (label
  `Title`, sentence capitalisation) and for the body (label `Body`, grey hint
  `What did you observe?`, multi-line, expands to fill the remaining
  height). A full-width `ElevatedButton` labelled `Save` with
  `Color(0xFF00695C)` background and white text, disabled while a save is in
  progress.
- **B37.** Save: title and body are trimmed. An empty trimmed title shows
  `errorText: 'Title is required'` under the title field and sends nothing.
  Otherwise the error is cleared and `NotesProvider.add(token, title, body)`
  is awaited. Success → `Navigator.pop` back to the notes screen, then toast
  `Saved`; the notes list shows the new note at the top. `ApiException` →
  toast `Could not save`; the screen stays open with the typed text and the
  button is enabled again. The title error is only re-evaluated on the next
  Save press (typing does not clear it).

## Settings screen (lib/screens/settings_screen.dart)

- **B38.** AppBar title `Settings`. A `SwitchListTile` labelled `Dark mode`
  bound to `SettingsProvider.isDark`; toggling calls `setDark` (B25) and the
  whole app re-themes at once, while the switch is on screen. A `ListTile`
  labelled `App version` with trailing grey text `1.0.0`, a hardcoded literal
  (not read from the package; `pubspec.yaml` says `1.0.0+1`).

## Not present (must stay absent unless the restructuring brief says otherwise)

- **B39.** No analytics events, no logging, no caching of server data, no
  offline queue, no background work, no deep links, no localisation (every
  string is an English literal listed below), no token refresh, no app-level
  error reporting.

## Every user-visible text

| Where | Text |
|---|---|
| App title (`MaterialApp.title`) | `Field notes` |
| Login AppBar, Notes AppBar | `Field notes` |
| Login fields | `Email`, hint `you@example.com`, `Password` |
| Login button | `Sign in` |
| Login toasts | `Welcome back`; on failure the `ApiException.message` (server `error`, or `Login failed`, `Request timed out`, `Network error`) |
| Notes tooltips | `Settings`, `Log out`, `New note` |
| Notes empty state | `No notes yet` |
| Notes error state | `Could not load notes` + button `Retry` |
| Notes toasts | `Note deleted`, `Could not delete note` |
| Note row date | `dd/MM/yyyy` in local time |
| New note AppBar | `New note` |
| New note fields | `Title`, `Body`, hint `What did you observe?` |
| New note validation | `Title is required` |
| New note button | `Save` |
| New note toasts | `Saved`, `Could not save` |
| Settings AppBar | `Settings` |
| Settings rows | `Dark mode`; `App version` → `1.0.0` |
| `ApiException` fallbacks never shown directly but observable in tests | `Failed to fetch notes`, `Failed to create note`, `Failed to delete note` |

## Persistence keys (SharedPreferences)

| Key | Type | Written | Removed |
|---|---|---|---|
| `auth_token` | String | after a successful login | on logout / unauthorized |
| `dark_mode` | bool | on every toggle of the switch | never |

## Tests that must stay green

- `test/models/note_test.dart` — `fromJson` reads every field; `fromJson →
  toJson` round trip equals the original map; `created_at` is ISO-8601.
- `test/providers/notes_provider_test.dart` — with a `FakeApiService extends
  ApiService` (methods overridden, no network): `remove` drops the note and
  notifies before the server answers; on failure it restores the note at its
  original index, notifies again and rethrows; an unknown id does nothing;
  `load` sets `Could not load notes` on `ApiException` and clears it on the
  next call; a 401 empties the list and calls `onUnauthorized`; `add` puts
  the created note first.
- `test/widget_test.dart` — with `SharedPreferences.setMockInitialValues({})`
  the app starts on the login screen (`Field notes`, `Sign in`); `Sign in` is
  disabled until both fields have text.
