import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'main_page.dart';
import 'roll_call_page.dart';
import 'voting_page.dart';
import 'settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase client
  await Supabase.initialize(
    url: 'https://cmcfmxqhelagntojgbvj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtY2ZteHFoZWxhZ250b2pnYnZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY5MzkwNDksImV4cCI6MjAzMjUxNTA0OX0.hKVU9b0FiRaxULBDmMA2QRODWRhEy1BigpG0MGdrSM8',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Model UN App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/roll-call': (context) => const RollCallPage(),
        '/voting': (context) => const VotingPage(),
        '/settings': (context) => const SettingsPage(),
        '/waiting': (context) => const WaitingPage(),
      },
    );
  }
}