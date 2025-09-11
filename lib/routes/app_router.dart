import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/home.dart' as home_screen; // 假设您有这个文件

// 创建路由配置
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return home_screen.HomeScreen(); // 或者您的主页组件
      },
      // 可以添加更多路由
    ),
  ],
);
