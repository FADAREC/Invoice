import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoice_app/screens/home_screen.dart';
import 'services/device_service.dart';
import 'database/database.dart';
import 'repositories/branch_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallel initialization
  final stopwatch = Stopwatch()..start();
  
  await Future.wait([
    _initDatabase(),
    _initDeviceId(),
  ]);

  stopwatch.stop();
  print('✅ App initialized in ${stopwatch.elapsedMilliseconds}ms');

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _initDatabase() async {
  final db = await AppDatabase.instance.database;
  
  // Ensure default branch exists
  final branchRepo = BranchRepository(db);
  await branchRepo.ensureDefaultBranch();
}

Future<void> _initDeviceId() async {
  await DeviceService.instance.getDeviceId();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            ),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      body: const Center(
        child: Text('Week 1 Foundation Complete ✅'),
      ),
    );
  }
}