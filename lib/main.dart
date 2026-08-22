import 'package:flutter/material.dart';
import 'package:task_flow/core/di/injection_container.dart' as di;
import 'package:task_flow/features/auth/presentation/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Dependency Injection
  await di.init();

  runApp(const TaskFlowApp());
}

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskFlowAppMaterial();
  }
}

class TaskFlowAppMaterial extends StatelessWidget {
  const TaskFlowAppMaterial({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,

      home: Splash(),
    );
  }
}
