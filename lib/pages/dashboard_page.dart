import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'dashboard_overview.dart';
import 'users_page.dart';
import 'products_page.dart';
import 'categories_page.dart';
import 'orders_page.dart';
import 'notifications_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardOverview(),
    UsersPage(),
    ProductsPage(),
    CategoriesPage(),
    OrdersPage(),
    NotificationsPage(),
  ];

  void _logout() {
    ApiService().setToken('');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).translate;
    final currentLocale = localeNotifier.value.languageCode;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: const Color(0xFF2C3E50),
            selectedIconTheme: const IconThemeData(color: Colors.white),
            selectedLabelTextStyle: const TextStyle(color: Colors.white),
            unselectedIconTheme: const IconThemeData(color: Colors.white60),
            unselectedLabelTextStyle: const TextStyle(color: Colors.white60),
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  const SizedBox(height: 12),
                  ToggleButtons(
                    isSelected: [currentLocale == 'ru', currentLocale == 'uz'],
                    onPressed: (index) {
                      final newLocale = index == 0 ? const Locale('ru') : const Locale('uz');
                      localeNotifier.value = newLocale;
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: Colors.white24,
                    color: Colors.white60,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 28),
                    children: const [
                      Text('RU', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('UZ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white60),
                    onPressed: _logout,
                    tooltip: t('logout'),
                  ),
                ),
              ),
            ),
            destinations: [
              NavigationRailDestination(
                icon: const Icon(Icons.dashboard),
                label: Text(t('dashboard')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.people),
                label: Text(t('users')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.inventory),
                label: Text(t('products')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.category),
                label: Text(t('categories')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.shopping_cart),
                label: Text(t('orders')),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.notifications),
                label: Text(t('notifications')),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
