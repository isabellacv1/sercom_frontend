import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import '../core/display_formatters.dart';
import '../widgets/postulation_form_sheet.dart';
import '../services/mission_service.dart';
import '../models/mission_model.dart';
import '../services/auth_service.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  String? _userName;
  final _missionService = MissionService();
  Set<String> _postulatedMissions = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPostulatedMissions();
  }

  Future<void> _loadUser() async {
    final name = await AuthService().getUserName();
    if (!mounted) return;

    setState(() {
      _userName = (name != null && name.trim().isNotEmpty)
          ? name.trim().split(' ').first
          : 'Trabajador';
    });
  }

  Future<void> _loadPostulatedMissions() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _postulatedMissions =
          (prefs.getStringList('postulatedMissions') ?? []).toSet();
    });
  }

  Future<void> _markAsPostulated(String missionId) async {
    setState(() => _postulatedMissions.add(missionId));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'postulatedMissions',
      _postulatedMissions.toList(),
    );
  }

  bool _isPostulable(MissionModel mission) {
    final status = mission.status.toLowerCase();

    final blockedStatuses = {
      'assigned',
      'in_progress',
      'completed',
      'finished',
      'cancelled',
      'canceled',
      'accepted',
      'closed',
    };

    return !blockedStatuses.contains(status) &&
        !_postulatedMissions.contains(mission.id);
  }

  List<MissionModel> _filterPostulableMissions(List<MissionModel> missions) {
    return missions.where(_isPostulable).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildMissionsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Misiones',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 28,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF0F172A),
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF64748B)),
                const SizedBox(width: 12),
                Text(
                  'Buscar misiones...',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList() {
    return FutureBuilder<List<MissionModel>>(
      future: _missionService.getMissionsByStatus('active'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 8),
              _buildShimmerList(),
            ],
          );
        }

        if (snapshot.hasError) {
          return ListView(
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'No se pudieron cargar las misiones.\nIntenta más tarde.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF64748B),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          );
        }

        final allMissions = snapshot.data ?? [];
        final missions = _filterPostulableMissions(allMissions);

        if (missions.isEmpty) {
          return ListView(
            children: [
              _buildHeroBanner(),
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: const Color(0xFF94A3B8).withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay misiones disponibles\npara postularte por ahora.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await _loadPostulatedMissions();
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: missions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildHeroBanner();
              return _buildMissionCard(missions[index - 1]);
            },
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 24,
            top: 0,
            bottom: 0,
            right: 150,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola ${_userName ?? 'Trabajador'}',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Aquí encontrarás misiones disponibles para postularte. Elige una oportunidad y envía tu propuesta.',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Image.asset(
              'assets/images/worker_3d.png',
              width: 140,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF1F5F9),
      highlightColor: Colors.white,
      child: Column(
        children: List.generate(
          2,
          (_) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard(MissionModel mission) {
    final priceMin = mission.priceMin ?? mission.minBudget;
    final priceMax = mission.priceMax ?? mission.maxBudget;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7A20),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.statusLabel ?? _statusText(mission.status),
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFFFF7A20),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (mission.createdAtRelative != null &&
                  mission.createdAtRelative!.isNotEmpty)
                Text(
                  mission.createdAtRelative!,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (mission.categoryName != null && mission.categoryName!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    color: Color(0xFFFF7A20),
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mission.categoryName!,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFFF7A20),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          Text(
            mission.serviceTitle ?? 'Servicio disponible',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 10),

          if (mission.description.isNotEmpty)
            Text(
              mission.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 14),

          Wrap(
            spacing: 18,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFFF7A20),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      _formatLocation(mission),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (priceMin != null || priceMax != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wallet_outlined,
                      color: Color(0xFFFF7A20),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatBudget(priceMin, priceMax),
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF7A20)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Detalles de la Misión',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFFF7A20),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    color: Color(0xFFFF7A20),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PostulationFormSheet(serviceId: mission.id),
                );

                if (result == true) {
                  await _markAsPostulated(mission.id);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A20),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Postularme a esta misión',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
      case 'requested':
      case 'receiving_offers':
        return 'Recibiendo postulaciones';
      case 'draft':
        return 'Borrador';
      default:
        return 'Disponible para postular';
    }
  }

  String _formatBudget(int? min, int? max) {
    if (min == null && max == null) return 'A convenir';

    final fMin = min != null ? formatCurrencyCop(min) : '';
    final fMax = max != null ? formatCurrencyCop(max) : '';

    if (fMin.isNotEmpty && fMax.isNotEmpty) return '$fMin - $fMax';
    return fMin.isNotEmpty ? fMin : fMax;
  }

  String _formatLocation(MissionModel mission) {
    final address = mission.address.trim();

    if (address.isEmpty) return 'Zona por confirmar';

    if (address.toLowerCase().contains('ubicación seleccionada')) {
      return 'Zona aproximada';
    }

    return address;
  }
}