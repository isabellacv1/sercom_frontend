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
    setState(() {
      _userName = (name != null && name.trim().isNotEmpty)
          ? name.trim().split(' ').first
          : null;
    });
  }

  Future<void> _loadPostulatedMissions() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _postulatedMissions =
          (prefs.getStringList('postulatedMissions') ?? []).toSet();
    });
  }

  Future<void> _markAsPostulated(String missionId) async {
    setState(() => _postulatedMissions.add(missionId));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'postulatedMissions', _postulatedMissions.toList());
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildMissionsList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────
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
                  icon: const Icon(Icons.notifications_none,
                      color: Color(0xFF0F172A)),
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

  // ─── MISSIONS LIST ───────────────────────────────────────────────────────────
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
          return ListView(children: [
            _buildHeroBanner(),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'No se pudo cargar las misiones.\nIntenta más tarde.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: const Color(0xFF64748B), fontSize: 15),
              ),
            ),
          ]);
        }

        final missions = snapshot.data ?? [];

        if (missions.isEmpty) {
          return ListView(children: [
            _buildHeroBanner(),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64,
                      color: const Color(0xFF94A3B8).withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay misiones disponibles\npor ahora.',
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
          ]);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: missions.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _buildHeroBanner();
            return _buildMissionCard(missions[index - 1]);
          },
        );
      },
    );
  }

  // ─── HERO BANNER ─────────────────────────────────────────────────────────────
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
                // Name: show shimmer-style placeholder if loading
                _userName == null
                    ? Container(
                        width: 120,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : Text(
                        'Hola $_userName',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                const SizedBox(height: 10),
                Text(
                  'Aquí encontraras las misiones disponibles para ti, haremos lo maximo para brindarte un excelente servicio para que saquemos este pais adelante',
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

  // ─── SHIMMER PLACEHOLDERS ────────────────────────────────────────────────────
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

  // ─── MISSION CARD ────────────────────────────────────────────────────────────
  Widget _buildMissionCard(MissionModel mission) {
    final isPostulated = _postulatedMissions.contains(mission.id);
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
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    mission.statusLabel ?? 'Recibiendo postulaciones',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFFF7A20),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
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

          // Category badge
          if (mission.categoryName != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFFF7A20), size: 14),
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

          // Title
          if (mission.serviceTitle != null)
            Text(
              mission.serviceTitle!,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),

          const SizedBox(height: 10),

          // Description
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

          // Info row: schedule + budget
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: Color(0xFFFF7A20), size: 18),
              const SizedBox(width: 8),
              Text(
                _formatSchedule(mission),
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (priceMin != null || priceMax != null) ...[
                const SizedBox(width: 24),
                const Icon(Icons.wallet_outlined,
                    color: Color(0xFFFF7A20), size: 18),
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
            ],
          ),

          const SizedBox(height: 20),

          // Actions row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF7A20)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
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
                        const Icon(Icons.arrow_forward,
                            color: Color(0xFFFF7A20), size: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Postulate / postulated button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isPostulated
                  ? null
                  : () async {
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) =>
                            PostulationFormSheet(serviceId: mission.id),
                      );
                      if (result == true) _markAsPostulated(mission.id);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPostulated
                    ? const Color(0xFFF1F5F9)
                    : const Color(0xFFFF7A20),
                disabledBackgroundColor: const Color(0xFFF1F5F9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPostulated) ...[
                    const Icon(Icons.check_circle,
                        color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Propuesta enviada',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Hacer una postulación para esta Misión',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.rocket_launch,
                        color: Colors.white, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  String _formatBudget(int? min, int? max) {
    if (min == null && max == null) return '';
    final fMin = min != null ? formatCurrencyCop(min) : '';
    final fMax = max != null ? formatCurrencyCop(max) : '';
    if (fMin.isNotEmpty && fMax.isNotEmpty) return '$fMin - $fMax';
    return fMin.isNotEmpty ? fMin : fMax;
  }

  String _formatSchedule(MissionModel mission) {
    return formatAvailabilityLabel(
      date: mission.scheduledDate,
      from: mission.scheduledFrom,
      to: mission.scheduledTo,
    );
  }


}
