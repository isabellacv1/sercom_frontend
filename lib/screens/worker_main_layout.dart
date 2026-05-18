import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'worker_home_screen.dart';
import 'postulations_screen.dart';
import 'profile_page.dart';
import 'chat_rooms_page.dart';
import 'worker_main_layout.dart';
import 'certifications_screen.dart';

class WorkerMainLayout extends StatefulWidget {
  const WorkerMainLayout({Key? key}) : super(key: key);

  @override
  State<WorkerMainLayout> createState() => _WorkerMainLayoutState();
}

class _WorkerMainLayoutState extends State<WorkerMainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const WorkerHomeScreen(),
    const CertificationsScreen(),
    const PostulationsScreen(),
    const ChatRoomsPage(role: 'worker'),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(Icons.home_rounded, 'Misiones', 0),
            _navItem(Icons.workspace_premium_rounded,'Cursos',1,),
            _navItem(Icons.list_alt_rounded, 'Solicitudes', 2),
            _navItem(Icons.chat_bubble_outline_rounded, 'Mensajes', 3),
            _navItem(Icons.person_outline_rounded, 'Perfil', 4),
          ],
        ),
        )
      ),
    );
  }

  Widget _navItem(
  IconData icon,
  String label,
  int index,
) {
  final active = _currentIndex == index;

  final color = active
      ? const Color(0xFFFF7A20)
      : const Color(0xFF94A3B8);

  return Expanded(
    child: InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFFFFF3EB)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: active
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

