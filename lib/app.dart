import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/foods/food_form_screen.dart';
import 'features/foods/foods_screen.dart';
import 'features/intake/add_intake_screen.dart';
import 'features/shell/app_shell.dart';
import 'features/targets/targets_screen.dart';
import 'features/today/today_screen.dart';
import 'models/food.dart';

abstract final class AppRoutes {
  static const today = '/today';
  static const foods = '/foods';
  static const targets = '/targets';
  static const addIntake = '/intake/add';
  static const foodForm = '/foods/form';
}

GoRouter createRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.today,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.today,
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.foods,
                builder: (context, state) => const FoodsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.targets,
                builder: (context, state) => const TargetsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addIntake,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const AddIntakeScreen(),
      ),
      GoRoute(
        path: AppRoutes.foodForm,
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          final extra = state.extra;
          return FoodFormScreen(existing: extra is Food ? extra : null);
        },
      ),
    ],
  );
}

class KcalApp extends StatefulWidget {
  const KcalApp({super.key});

  @override
  State<KcalApp> createState() => _KcalAppState();
}

class _KcalAppState extends State<KcalApp> {
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '热量账本',
      debugShowCheckedModeBanner: false,
      theme: kcalTheme(),
      routerConfig: _router,
    );
  }
}
