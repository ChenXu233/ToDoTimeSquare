import 'package:flutter/material.dart';
import '../../i18n/i18n.dart';
import '../../widgets/glass/gradient_background.dart';
import 'widgets/todo_list_widget.dart';

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = APPi18n.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(i18n.allTasks),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const TodoListWidget(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
