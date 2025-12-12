import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home.dart' as home_screen;
import '../screens/pomodoro/pomodoro_screen.dart';
import '../models/todo.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/todo/todo_list_screen.dart';
import '../screens/statistics/statistics.dart';

// 创建路由配置
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) {
        return const home_screen.HomeScreen();
      },
      routes: [
        GoRoute(
          path: 'pomodoro',
          builder: (BuildContext context, GoRouterState state) {
            final extra = state.extra;
            final Todo? todo = extra is Todo ? extra : null;
            return PomodoroScreen(initialTask: todo);
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (BuildContext context, GoRouterState state) {
            return const SettingsScreen();
          },
        ),
        GoRoute(
          path: 'todo',
          builder: (BuildContext context, GoRouterState state) {
            return const TodoListScreen();
          },
        ),
        GoRoute(
          path: 'statistics',
          builder: (BuildContext context, GoRouterState state) {
            return const StatisticsScreen();
          },
        ),
      ],
    ),
  ],
);
