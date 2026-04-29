import 'package:flutter/material.dart';
import 'core/supabase_client.dart';
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
import 'screens/service_confirmation_page.dart';
import 'screens/review_screen.dart';
import 'screens/chat_rooms_page.dart';
import 'screens/personal_info_page.dart';
import 'screens/worker_profile_page.dart';
import 'screens/worker_home_screen.dart';
import 'models/technician.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
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
        '/review': (context) => ReviewScreen(
          serviceId: ModalRoute.of(context)!.settings.arguments as String? ?? '',
        ),
        '/workerHome': (context) => const WorkerHomeScreen(),
        '/chat-rooms': (context) => const ChatRoomsPage(),
        '/personal-info': (context) => const PersonalInfoPage(),
        '/worker-profile': (context) => const WorkerProfilePage(),
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

        if (settings.name == '/service-confirmation') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => ServiceConfirmationPage(
              serviceId: args['serviceId'] as String,
              isWorker: args['isWorker'] as bool? ?? false,
              workerName: args['workerName'] as String?,
              workerPhotoUrl: args['workerPhotoUrl'] as String?,
              workerRating: args['workerRating'] as double?,
              workerReviewCount: args['workerReviewCount'] as int?,
              totalCost: args['totalCost'] as num?,
              scheduledAt: args['scheduledAt'] as String?,
              serviceTitle: args['serviceTitle'] as String?,
            ),
          );
        }

        return null;
      },
    );
  }
}