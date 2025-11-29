import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../i18n/i18n.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_background.dart';
import '../widgets/todo_list_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // PC Layout
                return Row(
                  children: [
                    // Left Sidebar / Dashboard
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i18n.appTitle,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              i18n.homeMessage,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                            ),
                            const SizedBox(height: 60),
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 1,
                                mainAxisSpacing: 24,
                                childAspectRatio: 2.5,
                                children: [
                                  _DashboardCard(
                                    title: i18n.pomodoroTitle,
                                    icon: Icons.timer_outlined,
                                    color: Colors.orangeAccent,
                                    onTap: () => context.go('/pomodoro'),
                                  ),
                                  _DashboardCard(
                                    title: i18n.settings,
                                    icon: Icons.settings_outlined,
                                    color: Colors.grey,
                                    onTap: () => context.go('/settings'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Right Side: Todo List Widget embedded
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(24),
                          color: isDark ? Colors.black : Colors.white,
                          opacity: 0.1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                i18n.allTasks,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 20),
                              const Expanded(child: TodoListWidget()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Mobile Layout
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        i18n.appTitle,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Focus. Organize. Achieve.",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 40),
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _DashboardCard(
                              title: i18n.pomodoroTitle,
                              icon: Icons.timer_outlined,
                              color: Colors.orangeAccent,
                              onTap: () => context.go('/pomodoro'),
                            ),
                            _DashboardCard(
                              title: i18n.allTasks,
                              icon: Icons.check_circle_outline,
                              color: Colors.blueAccent,
                              onTap: () => context.go('/todo'),
                            ),
                            _DashboardCard(
                              title: i18n.settings,
                              icon: Icons.settings_outlined,
                              color: Colors.grey,
                              onTap: () => context.go('/settings'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      color: isDark ? Colors.black : Colors.white,
      opacity: 0.1,
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 40, color: color),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
