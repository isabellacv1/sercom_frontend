import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';
import 'screens/category_services_page.dart';
import 'screens/create_mission_page.dart';
import 'screens/mission_dispatch_page.dart';
import 'screens/missions_page.dart';
import 'screens/match_confirmation_screen.dart';
import 'models/technician.dart';
import 'screens/technician_profile_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/category-services': (context) => const CategoryServicesPage(),
        '/create-mission': (context) => const CreateMissionPage(),
        '/mission-dispatch': (context) => const MissionDispatchPage(),
        '/missions': (context) => const MissionsPage(),
      },
    );
  }
}