import 'package:flutter/material.dart';

void main() {
  runApp(const KGPSLocatorApp());
}

class KGPSLocatorApp extends StatelessWidget {
  const KGPSLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KGPS-Locator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KGPS-Locator'),
      ),
      body: const Center(
        child: Text(
          'KGPS-Locator',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
