import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/definition/app_feature.dart';
import 'package:pochi_trim/data/definition/flavor.dart';
import 'package:pochi_trim/data/service/remote_config_service.dart';
import 'package:pochi_trim/ui/app_initial_route.dart';
import 'package:pochi_trim/ui/component/app_theme.dart';
import 'package:pochi_trim/ui/feature/auth/login_screen.dart';
import 'package:pochi_trim/ui/feature/home/home_screen.dart';
import 'package:pochi_trim/ui/feature/update/update_app_screen.dart';
import 'package:pochi_trim/ui/root_presenter.dart';

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> {
  @override
  void initState() {
    super.initState();

    ref
      ..listenManual(updatedRemoteConfigKeysProvider, (_, next) {
        next.maybeWhen(
          data: (keys) {
            // Remote Config の変更を監視し、次回 `RootApp` が生成された際に有効になるようにする。
            // リスナー側が何も行わなくても、ライブラリは変更された値を保持する。
            // https://firebase.google.com/docs/remote-config/loading#strategy_3_load_new_values_for_next_startup
            debugPrint('Updated remote config keys: $keys');
          },
          orElse: () {},
        );
      })
      ..listenManual(updatedUserIdProvider, (_, next) {
        // ユーザーIDの変更を常に監視しておき、必要な処理が行われるようにする
        next.maybeWhen(
          data: (maybeUserId) {
            final userId = maybeUserId ?? '(null)';
            debugPrint('Updated user ID: $userId');
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
      routes: {'/': (_) => const HomeScreen()},
      // `initialRoute` and `routes` are ineffective settings
      // that are set to avoid assertion errors.
      initialRoute: '/',
      onGenerateInitialRoutes: (_) => initialRoutes,
      navigatorObservers: navigatorObservers,
      title: 'ぽちそぎ',
      builder: (_, child) => _wrapByAppBanner(child),
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', 'JP'),
      ],
      debugShowCheckedModeBanner: showAppDebugBanner,
    );
  }

  Widget _wrapByAppBanner(Widget? child) {
    if (!showCustomAppBanner) {
      return child!;
    }

    final message = flavor.name.toUpperCase();

    final Color color;
    switch (flavor) {
      case Flavor.emulator:
        color = Colors.green;
      case Flavor.dev:
        color = Colors.blue;
      case Flavor.prod:
        color = Colors.red;
    }

    return Banner(
      message: message,
      location: BannerLocation.topEnd,
      color: color,
      child: child,
    );
  }
}
