import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

import '../core/display_formatters.dart';
import '../widgets/postulation_form_sheet.dart';
import '../services/mission_service.dart';
import '../models/mission_model.dart';
import '../services/auth_service.dart';
import 'mission_detail_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  static const String _seenNotificationsKey = 'seenOpportunityNotificationIds';

  String? _userName;

  final _missionService = MissionService();

  Set<String> _postulatedMissions = {};
  Set<String> _seenOpportunityNotifications = {};

  final List<MissionModel> _notificationMissions = [];

  int _newNotifications = 0;
  Timer? _pollingTimer;
  bool _loadingNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPostulatedMissions();
    _bootstrapOpportunityNotifications();
    _startOpportunityPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
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

  Future<void> _loadSeenOpportunityNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    _seenOpportunityNotifications =
        (prefs.getStringList(_seenNotificationsKey) ?? []).toSet();
  }

  Future<void> _saveSeenOpportunityNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _seenNotificationsKey,
      _seenOpportunityNotifications.toList(),
    );
  }

  Future<void> _bootstrapOpportunityNotifications() async {
    await _loadSeenOpportunityNotifications();
    await _loadOpportunityNotifications();
  }

  Future<void> _markAsPostulated(String missionId) async {
    if (!mounted) return;

    setState(() {
      _postulatedMissions.add(missionId);
    });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'postulatedMissions',
      _postulatedMissions.toList(),
    );
  }

  Future<void> _markNotificationsAsSeen(List<MissionModel> items) async {
    if (items.isEmpty) return;

    for (final mission in items) {
      _seenOpportunityNotifications.add(mission.id);
    }

    await _saveSeenOpportunityNotifications();

    if (!mounted) return;

    setState(() {
      _newNotifications = 0;
    });
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

  Future<List<MissionModel>> _loadOpportunityNotifications() async {
    if (_loadingNotifications) {
      return List<MissionModel>.from(_notificationMissions);
    }

    _loadingNotifications = true;

    try {
      final missions = _filterPostulableMissions(
        await _missionService.getAvailableOpportunities(),
      );

      final unreadCount = missions.where((mission) {
        return !_seenOpportunityNotifications.contains(mission.id);
      }).length;

      if (!mounted) return missions;

      setState(() {
        _notificationMissions
          ..clear()
          ..addAll(missions);

        _newNotifications = unreadCount;
      });

      return missions;
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      return List<MissionModel>.from(_notificationMissions);
    } finally {
      _loadingNotifications = false;
    }
  }

  void _startOpportunityPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 45), (_) async {
      if (!mounted) return;

      await _loadOpportunityNotifications();
    });
  }

  Future<void> _openNotificationsSheet() async {
    final items = await _loadOpportunityNotifications();

    if (!mounted) return;

    await _markNotificationsAsSeen(items);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        if (items.isEmpty) {
          return SizedBox(
            height: 280,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF94A3B8),
                    size: 46,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes solicitudes nuevas',
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF64748B),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: SizedBox(
            height: 480,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        'Solicitudes disponibles',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final mission = items[index];

                      return Material(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF7ED),
                            child: Icon(
                              Icons.work_outline_rounded,
                              color: Color(0xFFFF7A20),
                            ),
                          ),
                          title: Text(
                            mission.serviceTitle ??
                                'Nueva solicitud disponible',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${_formatLocation(mission)} • ${_formatAvailability(mission)} • ${_formatBudget(mission.priceMin ?? mission.minBudget, mission.priceMax ?? mission.maxBudget)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                          onTap: () async {
                            Navigator.pop(context);

                            final result = await Navigator.push(
                              this.context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MissionDetailScreen(mission: mission),
                              ),
                            );

                            if (result == true) {
                              await _markAsPostulated(mission.id);
                              await _loadOpportunityNotifications();

                              if (mounted) {
                                setState(() {});
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    await _loadOpportunityNotifications();
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

              // BOTÓN DE NOTIFICACIONES CON PUNTICO ROJO
              GestureDetector(
                onTap: _openNotificationsSheet,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Color(0xFF0F172A),
                        size: 28,
                      ),
                    ),
                    if (_newNotifications > 0)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
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
            await _loadPostulatedMissions();
            await _loadOpportunityNotifications();

            if (mounted) {
              setState(() {});
            }
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFFFF7A20),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatAvailability(mission),
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MissionDetailScreen(mission: mission),
                  ),
                );

                if (result == true) {
                  await _markAsPostulated(mission.id);
                  await _loadOpportunityNotifications();

                  if (mounted) {
                    setState(() {});
                  }
                }
              },
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
                  await _loadOpportunityNotifications();

                  if (mounted) {
                    setState(() {});
                  }
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
      case 'active':
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

  String _formatAvailability(MissionModel mission) {
    return formatAvailabilityLabel(
      date: mission.scheduledDate ?? mission.scheduledAt,
      from: mission.scheduledFrom,
      to: mission.scheduledTo,
      fallback: 'Fecha por confirmar',
    );
  }
}