import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/postulation_form_sheet.dart';
import '../services/mission_service.dart';
import '../models/mission_model.dart';
import '../services/auth_service.dart';
import 'profile_page.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _currentIndex = 0;
  String _userName = 'Trabajador';
  final _missionService = MissionService();
  bool _isLoading = true;
  List<MissionModel> _missions = [];
  Set<String> _postulatedMissions = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPostulatedMissions();
    _loadMissions();
  }

  Future<void> _loadPostulatedMissions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _postulatedMissions = (prefs.getStringList('postulatedMissions') ?? []).toSet();
    });
  }

  Future<void> _markAsPostulated(String missionId) async {
    setState(() {
      _postulatedMissions.add(missionId);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('postulatedMissions', _postulatedMissions.toList());
  }

  Future<void> _loadUser() async {
    final name = await AuthService().getUserName();
    if (name != null && name.isNotEmpty) {
      setState(() {
        _userName = name.split(' ').first; // Saludo con el primer nombre
      });
    }
  }

  Future<void> _loadMissions() async {
    try {
      final missions = await _missionService.getMyMissions();
      setState(() {
        _missions = missions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) { 
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hola, $_userName 👋',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF0F172A)),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Misiones Disponibles',
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _missions.isEmpty
                        ? Center(
                            child: Text(
                              'No hay misiones disponibles ahora.',
                              style: GoogleFonts.montserrat(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _missions.length,
                            itemBuilder: (context, index) {
                              final mission = _missions[index];
                              return _buildMissionCard(mission);
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFFFF8A00),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Mis Postulaciones'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _buildMissionCard(MissionModel mission) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mission.categoryName?.toUpperCase() ?? '',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                'Hace 2h',
                style: GoogleFonts.montserrat(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mission.serviceTitle ?? 'Misión Especial',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mission.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          _postulatedMissions.contains(mission.id)
              ? Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Light grey background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20), // Green check
                        const SizedBox(width: 8),
                        Text(
                          'Postulado',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PostulationFormSheet(
                          serviceId: mission.id,
                        ),
                      );

                      if (result == true) {
                        _markAsPostulated(mission.id);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Postularme',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
