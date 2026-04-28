import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/home_page.dart';
import 'screens/category_services_page.dart';
import 'screens/create_mission_page.dart';
import 'screens/mission_dispatch_page.dart';
import 'screens/missions_page.dart';
import 'screens/match_confirmation_screen.dart';
import 'screens/technician_profile_screen.dart';
import 'screens/role_selection_page.dart';
import 'screens/map_picker_page.dart';
import 'screens/chat_rooms_page.dart';

import 'models/technician.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/roles': (context) => const RoleSelectionPage(),
        '/home': (context) => const HomePage(),
        '/category-services': (context) => const CategoryServicesPage(),
        '/create-mission': (context) => const CreateMissionPage(),
        '/mission-dispatch': (context) => const MissionDispatchPage(),
        '/missions': (context) => const MissionsPage(),
        '/map-picker': (context) => const MapPickerPage(),
        '/chat-rooms': (context) => const ChatRoomsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/register') {
          final role = settings.arguments as String;

          return MaterialPageRoute(builder: (_) => RegisterPage(role: role));
        }

        if (settings.name == '/technician-profile') {
          final technician = settings.arguments as Technician;

          return MaterialPageRoute(
            builder: (_) => TechnicianProfileScreen(technician: technician),
          );
        }

        if (settings.name == '/match-confirmation') {
          final technician = settings.arguments as Technician;

          return MaterialPageRoute(
            builder: (_) => MatchConfirmationScreen(technician: technician),
          );
        }

        return null;
      },
    );
  }
}
