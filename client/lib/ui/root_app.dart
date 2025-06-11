import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pochi_trim/data/definition/app_feature.dart';
import 'package:pochi_trim/data/definition/flavor.dart';
import 'package:pochi_trim/data/service/auth_service.dart';
import 'package:pochi_trim/data/service/error_report_service.dart';
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
      // currentUserProfileの変更を監視してCrashlyticsのユーザーIDを同期
      ..listenManual(currentUserProfileProvider, (_, next) {
        final errorReportService = ref.read(errorReportServiceProvider);

        next.maybeWhen(
          data: (userProfile) async {
            if (userProfile == null) {
              // ユーザーがサインアウトしている場合、CrashlyticsのユーザーIDをクリア
              await errorReportService.clearUserId();
              return;
            }

            // ユーザーがサインインしている場合、CrashlyticsにユーザーIDを設定
            await errorReportService.setUserId(userProfile.id);
          },
          orElse: () {
            // ローディング中やエラー時は何もしない
          },
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
      title: 'ぽちそぎ',
      theme: getLightTheme(),
      darkTheme: getDarkTheme(),
      debugShowCheckedModeBanner: showAppDebugBanner,
      // `initialRoute` and `routes` are ineffective settings
      // that are set to avoid assertion errors.
      initialRoute: '/',
      routes: {'/': (_) => const HomeScreen()},
      onGenerateInitialRoutes: (_) => initialRoutes,
      navigatorObservers: navigatorObservers,
      builder: (_, child) => _wrapByAppBanner(child),
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
