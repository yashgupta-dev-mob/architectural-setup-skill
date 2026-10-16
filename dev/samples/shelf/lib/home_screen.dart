import 'package:flutter/material.dart';

import 'features/favourites/favourites_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/products/products_screen.dart';
import 'vendor/tracker.dart';

/// The `/` route: three tabs in an IndexedStack. A tab's screen is built
/// the first time it is selected and kept alive afterwards.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  final Set<int> _built = {0};

  @override
  void initState() {
    super.initState();
    ThirdPartyTracker.screen('Home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const ProductsScreen(),
          if (_built.contains(1))
            const FavouritesScreen()
          else
            const SizedBox.shrink(),
          if (_built.contains(2))
            const OrdersScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) {
          setState(() {
            _index = index;
            _built.add(index);
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}
