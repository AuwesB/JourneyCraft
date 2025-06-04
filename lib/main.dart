import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fcznoqjzuqefjgzcoonc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZjem5vcWp6dXFlZmpnemNvb25jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkwMTQwNTEsImV4cCI6MjA2NDU5MDA1MX0.xDEg2VCH4iv7Yz2x-Jwvce2Qy3k-ta7g2MXCbelTF1Y',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JourneyCraft',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
        title: const Text('JourneyCraft Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Text(
          'Supabase connected ✅',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
