import 'package:flutter/material.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Home"))));
      case '/auth':
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Auth"))));
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Dashboard"))));
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text("No route defined for ${settings.name}")),
          ),
        );
    }
  }
}
