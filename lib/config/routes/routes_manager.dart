// ignore_for_file: avoid_print
import 'package:flutter/material.dart';

class Routes {}

class RoutesManager {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    print("Mobile routeSettings.name: ${routeSettings.name}");
    // // case Routes.videoTrimmer:
    // //   Map<String, dynamic> arg =
    // //       routeSettings.arguments as Map<String, dynamic>;
    // //
    // //   return _materialRoute(
    // //     VideoTrimmerScreen(
    // //       file: arg["video"] as File,
    // //       maxDuration: arg["maxDuration"] as int,
    // //     ),
    // //   );
    // switch (routeSettings.name) {
    //   case Routes.splash:
    //     return _materialRoute(const SplashScreen());
    //
    //   default:
    //     return _materialRoute(const SplashScreen());
    // }
    return _materialRoute(Container());
  }

  static Route<dynamic> _materialRoute(Widget view) {
    return MaterialPageRoute(builder: (_) => view);
  }

  static Route<dynamic> unDefinedRoute(String name) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Not found")),
        body: Center(
          child: Text(name),
        ),
      ),
    );
  }
}
