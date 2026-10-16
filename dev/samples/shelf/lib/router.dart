import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/favourites/favourites_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/products/product_detail_screen.dart';
import 'home_screen.dart';
import 'net/client.dart';

class _RouterRefresh extends ChangeNotifier {
  void bump() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _RouterRefresh();
  ref.listen<AsyncValue<String?>>(authProvider, (_, _) => authRefresh.bump());

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: Listenable.merge([authRefresh, signedOut]),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;
      final loggedIn = auth.value != null && !signedOut.value;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/products/:id',
        builder: (_, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/favourites',
        builder: (_, _) => const FavouritesScreen(standalone: true),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, _) => const OrdersScreen(standalone: true),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    authRefresh.dispose();
  });
  return router;
});
