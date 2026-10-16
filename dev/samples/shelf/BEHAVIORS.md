# Shelf — behaviour manifest

Every numbered item below is an observable behaviour of the app that a
restructuring must preserve exactly. "Request" means an HTTP request made
through the app's single Dio client (`lib/net/client.dart`). "Prefs" means
`SharedPreferences`. All user-visible strings are quoted exactly, including
curly apostrophes where the code uses them (it does not: every apostrophe is
the ASCII `'`).

## Start-up and theme

- **B1.** `main()` runs, in this order: `WidgetsFlutterBinding.ensureInitialized()`,
  `await SharedPreferences.getInstance()`, `await ThirdPartyTracker.init('wk_live_1234567890')`
  (awaited before the first frame; the write key is this literal), then
  `runApp` of a `ProviderScope` whose only override provides the prefs
  instance, wrapping `ShelfApp`.
- **B2.** `ShelfApp` is a `MaterialApp.router` with `title: 'Shelf'` and
  `theme: ThemeData(colorSchemeSeed: const Color(0xFF6750A4), useMaterial3: true)`.
  No `darkTheme` and no `themeMode` are set, so the app renders this one light
  theme whatever the device's dark-mode setting.
- **B3.** The router's initial location is `/`. What is shown first depends only
  on the redirect rule (B17): with a saved session token the app opens on
  Home, otherwise on the login screen. Nothing is fetched before that.

## HTTP client

- **B4.** One `Dio` instance (`dio` in `lib/net/client.dart`) with
  `baseUrl: 'https://shelf-api.example.com'`, `connectTimeout: 15 s`,
  `receiveTimeout: 15 s`, no `sendTimeout`, and the base header
  `x-api-key: shelf_pk_123` on every request. All paths below are relative to
  that base URL. Request bodies are JSON (Dio's default JSON content type).
- **B5.** A request interceptor reads prefs key `session_token` before every
  request; when it is present and non-empty it adds
  `Authorization: Bearer <token>`. When absent or empty, no `Authorization`
  header is sent. The token is read from prefs at request time (not cached).
- **B6.** An error interceptor runs on every failed request: when the response
  status is **401**, it removes prefs key `session_token` and sets the global
  flag `signedOut` (a `ValueNotifier<bool>`) to `true`. The error then
  continues to the caller, so the feature that made the request also handles it
  as a failure (for example a 401 on `GET /store/products` both signs the user
  out and counts as a failed products refresh, B33/B34). No tracker call is
  made on a 401 sign-out.
- **B7.** Setting `signedOut` to `true` makes the session value `null` (B11) and
  makes the router redirect to `/login` (B17). It is set back to `false` only
  by a successful login (B13).
- **B8.** Dio's default `validateStatus` is used: only 2xx responses are
  successes; every other status, a timeout, a connection error, or a response
  body that cannot be parsed as described below counts as a failure of that
  request. No request is retried automatically anywhere in the app.

## Session (lib/features/auth)

- **B9.** The session is a Riverpod `AsyncNotifier<String?>` (`authProvider`)
  whose value is the session token, or `null` when signed out. Its initial
  value is read synchronously from prefs key `session_token` (present → that
  string; absent → `null`).
- **B10.** The login screen (`/login`) shows: an `AppBar` titled `Sign in`; the
  word `Shelf` in bold, 32 px, colour `0xFF6750A4`; two raw `TextField`s with
  outlined borders labelled `Email` (email keyboard, autocorrect off) and
  `Password` (obscured text); and a full-width `ElevatedButton` labelled
  `Sign in`. Submitting the keyboard action of the password field also
  submits the form.
- **B11.** While the auth provider is loading (the login request is in flight)
  the button is disabled and shows a 20×20 `CircularProgressIndicator`
  (stroke 2) instead of its label. When `signedOut` becomes `true` (B6) the
  session value becomes `null`.
- **B12.** Submitting with the trimmed email empty or the password empty makes
  **no request** and shows the SnackBar `Enter your email and password`.
- **B13.** Otherwise login sends `POST /auth/login` with body
  `{"email": "<trimmed email>", "password": "<password>"}`. On a 2xx response
  whose JSON body has string fields `access_token` and `user_id`, in this
  order: prefs `session_token` ← `access_token`; `signedOut` ← `false`;
  `ThirdPartyTracker.identify(user_id)`; the session value becomes the token;
  the login screen then calls `context.go('/')`. `user_id` is not persisted,
  so no `identify` happens on a later app start.
- **B14.** Any failure of the login request (non-2xx, timeout, connection
  error, a body missing either field or with a non-string value) shows the
  SnackBar `Login failed`, re-enables the button and keeps the user on
  `/login`. No `identify` is called.
- **B15.** Logout (the `Sign out` icon button, tooltip `Sign out`, `Icons.logout`,
  in the Products screen's app bar) makes **no request**. It removes prefs
  `session_token`, calls `ThirdPartyTracker.reset()`, sets the session value to
  `null`, then calls `context.go('/login')`. It does not clear the products
  cache, the favourites, or the in-memory orders list, and does not touch
  `signedOut`.

## Routing (lib/router.dart)

- **B16.** Routes are literal path strings: `/` → `HomeScreen`, `/login` →
  `LoginScreen`, `/products/:id` → `ProductDetailScreen(productId: id)`,
  `/favourites` → `FavouritesScreen(standalone: true)`, `/orders` →
  `OrdersScreen(standalone: true)`. There are no shell routes; `/favourites`
  and `/orders` are top-level pages that reuse the tab widgets.
- **B17.** Redirect rule, evaluated on every navigation and whenever the auth
  state or `signedOut` changes (`refreshListenable`): if the auth provider is
  loading → no redirect. Let `loggedIn = (token != null) && !signedOut`. If
  not logged in and the matched location is not `/login` → `/login`. If logged
  in and the matched location is `/login` → `/`. Otherwise no redirect.
- **B18.** Product cards and favourite rows open the detail with
  `context.push('/products/<id>')`, so the detail sits on top of the page it
  was opened from and the app bar's automatic back button pops it.
- **B19.** `Buy` on the detail (B45) and the back buttons of the standalone
  pages use `context.go(...)`: `go('/orders')` replaces the whole stack with
  the standalone Orders page; the standalone pages' `BackButton` calls
  `context.go('/')`, which shows a fresh Home on the Products tab.
- **B20.** After logout, navigation to `/login` happens both through
  `context.go('/login')` and the redirect; after login, to `/` the same way.
  The net result is one page, with no back stack.

## Home (lib/home_screen.dart)

- **B21.** `/` is a `Scaffold` whose body is an `IndexedStack` of the three tab
  screens and whose `bottomNavigationBar` is a Material `NavigationBar` with
  destinations, in order: `Products` (`Icons.storefront_outlined` /
  selected `Icons.storefront`), `Favourites` (`Icons.favorite_border` /
  `Icons.favorite`), `Orders` (`Icons.receipt_long_outlined` /
  `Icons.receipt_long`). The first tab is selected on every new Home instance.
- **B22.** Tabs are built lazily: `ProductsScreen` is built with Home; the
  Favourites and Orders screens are built the first time their tab is
  selected (until then their slot is an empty `SizedBox.shrink()`). Once
  built, a tab screen stays mounted while Home is mounted, so switching tabs
  keeps its state and triggers no reload.
- **B23.** `HomeScreen.initState` calls `ThirdPartyTracker.screen('Home')`.
  Because the Products tab is built with it, `screen('Products')` follows
  immediately (B70).

## Products (lib/features/products)

- **B24.** `Product` JSON: `id` (number or string; kept as its string form,
  required), `title` (string, required), `price` (number of paise, required,
  truncated to int), `thumbnail` (string, optional, `''` when missing),
  `in_stock` (bool, optional, `true` when missing). `toJson` writes those five
  keys with those names.
- **B25.** Cache: prefs key `products_cache` holds a JSON string
  `{"saved_at": "<ISO-8601>", "items": [<product JSON>, ...]}`. `saved_at`
  is written as the clock's time converted to UTC with
  `toIso8601String()` (e.g. `2026-01-01T12:00:00.000Z`).
- **B26.** Cache read (when the products provider is created): the entry is
  used only when `now - saved_at < 10 minutes` (strictly less). An entry
  exactly 10 minutes old or older is **deleted** from prefs and ignored. An
  entry that cannot be parsed (not JSON, missing/invalid `saved_at`, bad
  item) is also deleted and ignored. A fresh entry is used whatever its
  length, including an empty `items` list.
- **B27.** The products provider is created the first time anything watches
  it: the Products tab when Home is first shown, or a detail / favourites
  screen if one is reached first. It lives for the rest of the process (it is
  never disposed or reset, not even on logout).
- **B28.** On creation: with a fresh cache the state immediately holds the
  cached items (`hasData = true`, `fromCache = true`) and they are shown at
  once; with no usable cache the state is "loading" and the screen shows a
  centred `CircularProgressIndicator`. In both cases a refresh (B29) starts in
  a microtask right after creation.
- **B29.** A refresh sends `GET /store/products?limit=100` (query parameter
  `limit=100`). A 2xx body must be a JSON object with a `products` array of
  product JSON; anything else is a failure. Refresh calls made while one is in
  flight share that request (no second request).
- **B30.** On success the list is replaced by the server's list (in server
  order), `fromCache` becomes `false`, and the cache is rewritten (B25) with
  the new list and the current time. A failed cache write is ignored.
- **B31.** On failure while a list is shown (cached or earlier server data):
  the shown items stay, the cache entry is **not** modified, and the
  Products screen shows the SnackBar `Couldn't refresh products` — once per
  failed refresh (a counter in the state increments; the screen listens for
  increments).
- **B32.** On failure with nothing to show: the Products screen shows the error
  view: the text `Couldn't load products` above an `ElevatedButton` labelled
  `Try again`. `Try again` starts a refresh: the spinner shows again, then the
  list on success or the error view on failure. No SnackBar is shown in this
  case.
- **B33.** After a successful load of an empty list (or a fresh cache with an
  empty list) the body is the centred text `No products`.
- **B34.** With items, the body is a `RefreshIndicator` over a `ListView` of
  product cards; pull-to-refresh runs a refresh and the indicator stays until
  it finishes.
- **B35.** The Products screen's `AppBar` is titled `Products` and has one
  action: the `Sign out` icon button (B15).
- **B36.** A product card is a `Card` containing a `ListTile`: leading 56×56
  thumbnail (B37); title = `title` (max 2 lines, ellipsis); subtitle row =
  `formatPaise(price)` in semi-bold followed by `In stock` in colour
  `0xFF2E7D32` or `Out of stock` in colour `0xFFB3261E` (12 px); trailing =
  the favourite heart (B50); tapping the tile pushes `/products/<id>`.
- **B37.** Thumbnails (`ProductThumbnail`) are 8 px-rounded squares with
  background `0xFFEEEEEE`. An empty URL shows `Icons.image_outlined` in
  `0xFF9E9E9E`; a URL that fails to load shows `Icons.broken_image_outlined`
  in `0xFF9E9E9E`; otherwise `Image.network(url, fit: BoxFit.cover)`.

## Product detail (`/products/:id`)

- **B38.** `ProductDetailScreen.initState` calls
  `ThirdPartyTracker.screen('ProductDetail')`.
- **B39.** The product is looked up by id in the products provider's current
  list (no request of its own). While the list has no data and is loading, the
  body is a centred `CircularProgressIndicator`; when the id is not in the
  list, the body is the centred text `Product not found`. The `AppBar` title
  is the product's `title`, or `Product` while it is unknown.
- **B40.** `ThirdPartyTracker.track('product_viewed', {'product_id': <id String>, 'price': <paise int>})`
  fires once per detail screen instance, the first time the product is
  rendered: immediately when it is already in the list, otherwise when the
  list arrives. It never fires for a product that is not found.
- **B41.** When the product is known the `AppBar` has the favourite heart (B50)
  as its action.
- **B42.** Body (a `ListView`, 16 px padding): a 220×220 thumbnail, centred;
  the title in `headlineSmall`; `formatPaise(price)` in `titleLarge`, bold,
  colour `0xFF6750A4`; a `Chip` reading `In stock` (label colour `0xFF2E7D32`,
  background `0xFFE8F5E9`) or `Out of stock` (label `0xFFB3261E`, background
  `0xFFFDECEA`); then an `ElevatedButton.icon` with `Icons.shopping_bag_outlined`
  labelled `Buy`.
- **B43.** `Buy` is disabled (`onPressed: null`) when `inStock` is false.
- **B44.** Tapping `Buy` makes **no request**. It fires
  `ThirdPartyTracker.track('buy_tapped', {'product_id': <id>, 'price': <paise>})`,
  shows the SnackBar `Order placed`, and calls `context.go('/orders')`
  (B19), so the standalone Orders page opens and reloads (B58).

## Favourites (lib/features/favourites) — device-first

- **B45.** Storage: prefs key `favourites` holds a JSON string
  `{"ids": ["<product id>", ...], "pending": <bool>}`. On provider creation
  it is read once: a missing key or an unparseable value gives an empty list
  with `pending = false`; `ids` elements are stringified; a missing `pending`
  reads as `false`.
- **B46.** The favourites provider is created the first time anything watches
  it — in practice when Home first shows the Products tab (every card's heart
  watches it) — and lives for the rest of the process. Logout does not clear
  or reset it; a later login reuses the same device list.
- **B47.** Toggle (`toggle(id)`): if `id` is in the list it is removed,
  otherwise appended at the end. The state (and so every heart) updates
  immediately; `pending` becomes `true`; then
  `ThirdPartyTracker.track('favourite_toggled', {'product_id': <id>, 'on': <bool: true when added>})`
  fires; the new list is saved to prefs with `"pending": true`; then a push
  (B48) starts in the background. Toggle never waits for the network.
- **B48.** Push: sends `PUT /me/favourites` with body `{"ids": [<the list at
  the moment the push started>]}`. On a 2xx (body ignored): if the list is
  still equal to the one sent, `pending` becomes `false` and prefs is saved
  with `"pending": false`; if the list changed meanwhile nothing changes (the
  later toggle's own push settles it). On any failure nothing changes and
  nothing is shown: the list stays `pending` on the device.
- **B49.** Sync on start (runs once, in a microtask right after the provider is
  created): if `pending` is `true`, the device list is pushed (B48) and
  **no GET** is made. Otherwise `GET /me/favourites` is sent; its 2xx body
  must be a JSON object with an `ids` array (elements stringified). The
  server list replaces the device list (saved with `"pending": false`) unless
  a toggle happened while the request was out (`pending` is then `true` and
  the result is dropped). A failed GET changes nothing, silently.
- **B50.** The heart (`FavouriteButton`) is an `IconButton`: when the product is
  a favourite it shows `Icons.favorite` in colour `0xFFE53935` with tooltip
  `Remove from favourites`; otherwise `Icons.favorite_border` in the default
  icon colour with tooltip `Add to favourites`. Tapping calls toggle (B47).
  It appears on every product card (B36), in the detail app bar (B41) and on
  every favourites row (B52).
- **B51.** `FavouritesScreen.initState` calls `ThirdPartyTracker.screen('Favourites')`
  (first selection of the tab in a Home instance, or the `/favourites` route).
  Its `AppBar` is titled `Favourites`; when `standalone` is true it has a
  `BackButton` that calls `context.go('/')`, otherwise no leading widget.
- **B52.** Body: when `ids` is empty, the centred text `No favourites yet`.
  Otherwise a `ListView` with one `ListTile` per favourite id, in the order
  of `ids`, **only for ids present in the products provider's current list**
  (an id whose product is not loaded is not shown; the rows appear once the
  list arrives). Row: leading 48×48 thumbnail, title = product title,
  subtitle = `formatPaise(price)`, trailing heart (B50), tap pushes
  `/products/<id>`.

## Orders (lib/features/orders) — network-only, paginated

- **B53.** `Order` JSON: `id` (number or string, kept as a string, required),
  `total` (number of paise, required), `status` (string, optional, `unknown`
  when missing), `created_at` (ISO-8601 string, required). Nothing about
  orders is ever written to prefs or any cache.
- **B54.** A page is `GET /me/orders?page=<N>&limit=20`, pages starting at 1.
  Its 2xx body must be a JSON object with an `orders` array. A **404** is
  treated as an empty page (success with zero orders). Any other failure is a
  load failure (B57).
- **B55.** State: `orders` (all pages so far, in order), `nextPage`, `hasMore`,
  `isLoading`, `loadedOnce`, `failures` counter. `hasMore` is `true` when the
  page just received had 20 or more orders. A reload or load-more call made
  while a request is in flight is ignored.
- **B56.** Reload drops the list and loads page 1; on success the list is that
  page. Load more requests `nextPage` and appends it. On success of either,
  `nextPage` advances by one.
- **B57.** On failure (any non-404 failure): the `failures` counter increments
  and the Orders screen shows the SnackBar `Could not load orders` (once per
  failure). After a failed reload nothing is loaded (`loadedOnce` false); after
  a failed load-more the orders already shown stay and `hasMore` keeps its
  value, so `Load more` reappears.
- **B58.** `OrdersScreen.initState` calls `ThirdPartyTracker.screen('Orders')` and,
  in a microtask, triggers a reload. So page 1 is loaded (replacing any
  earlier list) every time an Orders screen is mounted: the first selection of
  the Orders tab in a Home instance, and every visit to the `/orders` route.
  Switching back to an already-built tab does not reload.
- **B59.** `AppBar`: titled `Orders`; when `standalone` is true a `BackButton`
  calling `context.go('/')`, otherwise no leading widget; one action, the
  `Refresh` icon button (`Icons.refresh`, tooltip `Refresh`) which reloads.
- **B60.** Body: before any page has been received, a centred
  `CircularProgressIndicator` while loading, or — after a failed reload — a
  centred `OutlinedButton` labelled `Retry` that reloads. After a successful
  load with zero orders, the centred text `No orders yet`. Otherwise a
  `ListView` of order tiles followed by one footer item: a centred
  `CircularProgressIndicator` while loading more; an `OutlinedButton` labelled
  `Load more` when `hasMore` is true; otherwise a 16 px empty spacer.
- **B61.** An order tile is a `ListTile`: leading `Icons.receipt_long` coloured
  by status (compared in lower case): `delivered` → `0xFF2E7D32`,
  `cancelled` → `0xFFB3261E`, anything else → `0xFFEF6C00`; title
  `Order #<id>`; subtitle `<status> · <dd/MM/yyyy>` (the raw status string, a
  middle dot with spaces, the `created_at` date in the device's local time
  zone, zero-padded day and month); trailing `formatPaise(total)` in
  semi-bold.

## Money formatting (lib/utils/money.dart)

- **B62.** `formatPaise(int paise)`: `₹` + rupees + `.` + two-digit paise, with
  Indian digit grouping (last three digits, then groups of two):
  `0 → ₹0.00`, `5 → ₹0.05`, `123450 → ₹1,234.50`, `100000 → ₹1,000.00`,
  `12345600 → ₹1,23,456.00`, `1234567890 → ₹1,23,45,678.90`. A negative
  amount puts `-` before `₹`: `-150 → -₹1.50`. Used for every price and total
  shown in the app.

## Feedback

- **B63.** Every message is shown with `ScaffoldMessenger.of(context).showSnackBar`
  using a plain `SnackBar(content: Text(...))` with the default duration and
  no action. Because the tab screens are nested `Scaffold`s, SnackBars appear
  in the root Scaffold (above Home's `NavigationBar`). The complete list of
  SnackBar texts: `Enter your email and password`, `Login failed`,
  `Couldn't refresh products`, `Could not load orders`, `Order placed`.
- **B64.** No dialogs are used anywhere. No failure crashes the app: every
  request failure is caught and handled as described above.

## Persistence keys

- **B65.** Exactly three prefs keys are used: `session_token` (string, B5/B9/B13/B15/B6),
  `products_cache` (JSON string, B25/B26/B30), `favourites` (JSON string,
  B45/B47/B48/B49). Nothing else is persisted. `products_cache` and
  `favourites` survive logout; `session_token` is removed by logout and by a
  401.

## Analytics (lib/vendor/tracker.dart — the pretend SDK)

- **B66.** The SDK's API is `ThirdPartyTracker.init(writeKey)`, `track(event, props)`,
  `screen(name)`, `identify(userId)`, `reset()`. Its only effect is a
  `debugPrint` per call; the call sites are the contract, the printed format
  is not.
- **B67.** `init('wk_live_1234567890')` once, awaited in `main()` before `runApp`.
- **B68.** `identify(user_id)` on every successful login (B13). `reset()` on
  logout only (B15), not on a 401.
- **B69.** `track` events and their properties:
  `product_viewed` `{product_id: String, price: int}` (B40);
  `favourite_toggled` `{product_id: String, on: bool}` on every toggle, before
  the push (B47); `buy_tapped` `{product_id: String, price: int}` (B44). No
  other `track` calls exist.
- **B70.** `screen(name)` in each screen's `initState`, so once per mount:
  `Login` (login screen), `Home` (each new Home), `Products` (built together
  with Home, right after `Home`), `Favourites` and `Orders` (first selection of
  that tab in a Home instance, and each visit to the standalone route),
  `ProductDetail` (each push of a detail). Switching back to an already-built
  tab fires nothing.

## Hardcoded colours in widgets (must keep the same values)

- **B71.** `0xFF6750A4`: theme seed (B2), the `Shelf` headline on login (B10),
  the detail price (B42). `0xFF2E7D32` / `0xFFB3261E`: in-stock / out-of-stock
  text on cards, the detail chip label, delivered / cancelled order icons.
  `0xFFE8F5E9` / `0xFFFDECEA`: detail chip backgrounds. `0xFFE53935`: the
  active heart. `0xFFEEEEEE` / `0xFF9E9E9E`: thumbnail background / placeholder
  icons. `0xFFEF6C00`: any other order status icon.

## Tests that must stay green

- **B72.** `test/utils/money_test.dart` (B62), `test/features/products_cache_test.dart`
  (B26/B28–B32 with an injected clock, using a subclass of the products
  notifier whose network call is replaced), `test/features/favourites_pending_test.dart`
  (B47–B49 using a subclass of the favourites notifier whose two network
  calls are replaced by completers), and `test/app_smoke_test.dart` (B3/B10
  and the cache-first start of B28/B31). They construct the app's providers
  directly with `ProviderContainer` overrides for `sharedPreferencesProvider`
  (from `lib/globals.dart`) and `clockProvider`; no mocking package is used.
