import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../services/mission_service.dart';

import 'home_page.dart';
import 'worker_main_layout.dart';
import 'worker_onboarding_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _authService = AuthService();
  final _missionService = MissionService();

  String _userName = 'Cargando...';
  String _userRole = 'client';
  String? _profilePhotoUrl;

  int _totalMissions = 0;
  int _finishedMissions = 0;
  double _ranking = 0.0;

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
  try {
    await _authService.getCurrentProfile();

    final name = await _authService.getUserName() ?? 'Usuario';
    final role = await _authService.getUserRole() ?? 'client';
    final photoUrl = await _authService.getUserPhotoUrl();

    final missions = await _missionService.getMyMissions();

    final finishedMissions = missions.where((mission) {
      final status = mission.status.toLowerCase();

      return status == 'finalizado' ||
          status == 'finalizada' ||
          status == 'finished' ||
          status == 'completed';
    }).length;

    if (!mounted) return;

    setState(() {
      _userName = name;
      _userRole = role;
      _profilePhotoUrl = photoUrl;
      _totalMissions = missions.length;
      _finishedMissions = finishedMissions;
      _ranking = 0.0;
      _isLoadingProfile = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _userName = 'Usuario';
      _userRole = 'client';
      _profilePhotoUrl = null;
      _totalMissions = 0;
      _finishedMissions = 0;
      _ranking = 0.0;
      _isLoadingProfile = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error cargando perfil: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> _switchRole() async {
    final newRole = _userRole == 'worker' ? 'client' : 'worker';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await _authService.switchRole(newRole);

      if (!mounted) return;

      Navigator.pop(context);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) {
            return newRole == 'worker'
                ? const WorkerMainLayout()
                : const HomePage();
          },
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      Navigator.pop(context);

      final errorMsg = e.toString();

      if (errorMsg.contains('USER_NOT_ACTIVATED_AS_WORKER') ||
          errorMsg.contains('400')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const WorkerOnboardingPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = _userRole == 'worker';

    final mainColor =
        isWorker ? const Color(0xFFFF7A20) : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildProfileAvatar(),
                      const SizedBox(height: 16),
                      Text(
                        _userName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isWorker
                            ? 'Usuario Premium • Trabajador'
                            : 'Usuario Premium • Cliente',
                        style: GoogleFonts.montserrat(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatBlock(
                            _totalMissions.toString(),
                            'Misiones',
                          ),
                          _buildStatBlock(
                            _finishedMissions.toString(),
                            'Finalizadas',
                          ),
                          _buildStatBlock(
                            _ranking == 0.0
                                ? '-'
                                : _ranking.toStringAsFixed(1),
                            'Ranking',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadProfileData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _switchRole,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF8A00),
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1E8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.switch_account,
                                      color: Color(0xFFFF8A00),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isWorker
                                              ? 'Cambiar a Modo Cliente'
                                              : 'Cambiar a Modo Trabajador',
                                          style: GoogleFonts.montserrat(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isWorker
                                              ? 'Busca servicios y publica misiones'
                                              : 'Realiza misiones y gana dinero',
                                          style: GoogleFonts.montserrat(
                                            color: Colors.grey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Mi Cuenta',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                _buildAccountOption(
                                  Icons.badge,
                                  'Información Personal',
                                  isWorker,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/personal-info',
                                    );
                                  },
                                ),
                                const Divider(height: 1, indent: 60),
                                _buildAccountOption(
                                  Icons.assignment_outlined,
                                  'Mis Misiones',
                                  isWorker,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/missions',
                                    );
                                  },
                                ),
                                const Divider(height: 1, indent: 60),
                                _buildAccountOption(
                                  Icons.credit_card,
                                  'Métodos de Pago',
                                  isWorker,
                                ),
                                const Divider(height: 1, indent: 60),
                                _buildAccountOption(
                                  Icons.notifications,
                                  'Notificaciones',
                                  isWorker,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: _logout,
                              child: Text(
                                'Cerrar Sesión',
                                style: GoogleFonts.montserrat(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  Widget _buildProfileAvatar() {
  final hasPhoto =
      _profilePhotoUrl != null && _profilePhotoUrl!.trim().isNotEmpty;

  return Container(
    width: 104,
    height: 104,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white,
    ),
    child: ClipOval(
      child: hasPhoto
          ? Image.network(
              _profilePhotoUrl!.trim(),
              width: 104,
              height: 104,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person,
                  size: 52,
                  color: Colors.grey,
                );
              },
            )
          : const Icon(
              Icons.person,
              size: 52,
              color: Colors.grey,
            ),
    ),
  );
}

  Widget _buildStatBlock(String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  

  Widget _buildAccountOption(
    IconData icon,
    String title,
    bool isWorker, {
    VoidCallback? onTap,
  }) {
    final mainColor =
        isWorker ? const Color(0xFFFF7A20) : const Color(0xFF2563EB);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: mainColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: mainColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}