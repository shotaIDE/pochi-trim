import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:house_worker/common/theme/app_theme.dart';
import 'package:house_worker/features/auth/login_screen.dart';
import 'package:house_worker/features/home/home_screen.dart';
import 'package:house_worker/flavor_config.dart';
import 'package:house_worker/root_app_session.dart';
import 'package:house_worker/root_presenter.dart';

class RootApp extends ConsumerStatefulWidget {
  const RootApp({super.key});

  @override
  ConsumerState<RootApp> createState() => _RootAppState();
}

class _RootAppState extends ConsumerState<RootApp> {
  @override
  void initState() {
    super.initState();

    ref.read(rootAppInitializedProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    final rootAppSession = ref.watch(rootAppInitializedProvider);

    final List<MaterialPageRoute<Widget>> initialRoutes;

    switch (rootAppSession) {
      case AppSessionSignedIn():
        initialRoutes = [HomeScreen.route()];
      case AppSessionNotSignedIn():
        initialRoutes = [LoginScreen.route()];
      case AppSessionLoading():
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
