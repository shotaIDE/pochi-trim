import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/app_initial_route.dart';
import 'package:house_worker/common/theme/app_theme.dart';
import 'package:house_worker/features/auth/login_screen.dart';
import 'package:house_worker/features/home/home_screen.dart';
import 'package:house_worker/features/update/update_app_screen.dart';
import 'package:house_worker/flavor_config.dart';
import 'package:house_worker/root_presenter.dart';
import 'package:house_worker/services/remote_config_service.dart';

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> {
  @override
  void initState() {
    super.initState();

    ref.listenManual(updatedRemoteConfigKeysProvider, (_, next) {
      next.maybeWhen(
        data: (keys) {
          // Remote Config の変更を監視し、次回 `RootApp` が生成された際に有効になるようにする。
          // リスナー側が何も行わなくても、ライブラリは変更された値を保持する。
          // https://firebase.google.com/docs/remote-config/loading#strategy_3_load_new_values_for_next_startup
          debugPrint('Updated remote config keys: $keys');
        },
        orElse: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final appInitialRouteAsync = ref.watch(appInitialRouteProvider);
    final appInitialRoute = appInitialRouteAsync.whenOrNull(
      data: (appInitialRoute) => appInitialRoute,
    );
    if (appInitialRoute == null) {
      return Container();
    }

    final List<MaterialPageRoute<Widget>> initialRoutes;

    switch (appInitialRoute) {
      case AppInitialRoute.updateApp:
        initialRoutes = [UpdateAppScreen.route()];
      case AppInitialRoute.login:
        initialRoutes = [LoginScreen.route()];
      case AppInitialRoute.home:
        initialRoutes = [HomeScreen.route()];
    }

    final navigatorObservers = <NavigatorObserver>[
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ];

    return MaterialApp(
      title: 'House Worker ${FlavorConfig.instance.name}',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      debugShowCheckedModeBanner: !FlavorConfig.isProd,
      // `initialRoute` and `routes` are ineffective settings
      // that are set to avoid assertion errors.
      initialRoute: '/',
      routes: {'/': (_) => const HomeScreen()},
      onGenerateInitialRoutes: (_) => initialRoutes,
      navigatorObservers: navigatorObservers,
      builder: (context, child) {
        // Flavorに応じたバナーを表示（本番環境以外）
        if (!FlavorConfig.isProd) {
          return Banner(
            message: FlavorConfig.instance.name,
            location: BannerLocation.topEnd,
            color: FlavorConfig.instance.color,
            child: child,
          );
        }
        return child!;
      },
    );
  }
}
