import 'package:flutter/material.dart';
import '../core/display_formatters.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';
import 'candidate_list_screen.dart';
import 'service_confirmation_page.dart';

class MissionsPage extends StatefulWidget {
  const MissionsPage({super.key});

  @override
  State<MissionsPage> createState() => _MissionsPageState();
}

class _MissionsPageState extends State<MissionsPage> {
  final MissionService _missionService = MissionService();

  bool isLoading = true;
  int selectedTab = 0;
  List<MissionModel> missions = [];

  @override
  void initState() {
    super.initState();
    loadMissions();
  }

  Future<void> loadMissions() async {
    try {
      final result = await _missionService.getMyMissions();

      if (!mounted) return;

      setState(() {
        missions = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        missions = [];
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando misiones: $e')),
      );
    }
  }

  String normalizeStatus(String status) {
    return status.trim().toLowerCase();
  }

  bool isProposalStatus(MissionModel mission) {
    final status = normalizeStatus(mission.status);

    return status == 'requested' ||
        status == 'pending' ||
        status == 'receiving_offers';
  }

  bool isInCourseStatus(MissionModel mission) {
    final status = normalizeStatus(mission.status);

    return status == 'assigned' ||
        status == 'confirmed' ||
        status == 'on_the_way' ||
        status == 'in_progress';
  }

  bool isFinishedStatus(MissionModel mission) {
    final status = normalizeStatus(mission.status);

    return status == 'finished' ||
        status == 'completed' ||
        status == 'cancelled';
  }

  bool shouldShowDetailsButton(MissionModel mission) {
    return isInCourseStatus(mission) || isFinishedStatus(mission);
  }

  String getStatusLabel(String status) {
    final normalizedStatus = normalizeStatus(status);

    switch (normalizedStatus) {
      case 'requested':
        return 'Solicitado';
      case 'pending':
        return 'Buscando trabajadores';
      case 'receiving_offers':
        return 'Recibiendo postulaciones';
      case 'assigned':
        return 'Asignado';
      case 'confirmed':
        return 'Confirmada';
      case 'on_the_way':
        return 'En camino';
      case 'in_progress':
        return 'En ejecución';
      case 'finished':
        return 'Finalizada';
      case 'completed':
        return 'Finalizada';
      case 'cancelled':
        return 'Cancelada';
      default:
        return status.isEmpty ? 'Sin estado' : status;
    }
  }

  Color getStatusColor(String status) {
    final normalizedStatus = normalizeStatus(status);

    switch (normalizedStatus) {
      case 'requested':
      case 'pending':
        return const Color(0xFFEAB308);
      case 'receiving_offers':
        return const Color(0xFF2563EB);
      case 'assigned':
      case 'confirmed':
        return const Color(0xFF22C55E);
      case 'on_the_way':
      case 'in_progress':
        return const Color(0xFF6366F1);
      case 'finished':
      case 'completed':
        return const Color(0xFF64748B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF2563EB);
    }
  }

  List<MissionModel> get filteredMissions {
    if (selectedTab == 0) {
      return missions
          .where(
            (m) => !isInCourseStatus(m) && !isFinishedStatus(m),
          )
          .toList();
    }

    if (selectedTab == 1) {
      return missions.where((m) => isInCourseStatus(m)).toList();
    }

    return missions.where((m) => isFinishedStatus(m)).toList();
  }

  String getBudgetText(MissionModel mission) {
    final min = mission.priceMin ?? mission.minBudget;
    final max = mission.priceMax ?? mission.maxBudget;

    if (min != null && min > 0 && max != null && max > 0) {
      return '${formatCurrencyCop(min)} - ${formatCurrencyCop(max)}';
    }

    if (min != null && min > 0) return formatCurrencyCop(min);
    if (max != null && max > 0) return formatCurrencyCop(max);

    return 'A convenir';
  }

  String getScheduleText(MissionModel mission) {
    final date = mission.scheduledDate ?? mission.scheduledAt;

    return formatAvailabilityLabel(
      date: date,
      from: mission.scheduledFrom,
      to: mission.scheduledTo,
    );
  }

  String getProposalButtonText(MissionModel mission) {
    if (shouldShowDetailsButton(mission)) {
      return 'Ver detalles';
    }

    final count = mission.offerCount;
    if (count == null) return 'Ver propuestas';
    return 'Ver propuestas ($count)';
  }

  String getEmptyMessage() {
    if (selectedTab == 0) return 'No tienes misiones activas';
    if (selectedTab == 1) return 'No tienes misiones en curso';
    return 'No tienes misiones finalizadas';
  }

  Future<void> goToMissionDetails(MissionModel mission) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceConfirmationPage(
          serviceId: mission.id,
          isWorker: false,
          serviceTitle: mission.serviceTitle,
          scheduledAt: mission.scheduledAt ?? mission.scheduledDate,
          totalCost: (mission.priceMin ?? 0) > 0
              ? mission.priceMin
              : mission.priceMax,
        ),
      ),
    );

    if (!mounted) return;
    loadMissions();
  }

  Future<void> goToProposals(MissionModel mission) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CandidateListScreen(
          serviceId: mission.id,
          mission: mission,
        ),
      ),
    );

    if (!mounted) return;
    loadMissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Mis Misiones',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.notifications,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        _buildTab('Activas', 0),
                        _buildTab('En curso', 1),
                        _buildTab('Historial', 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMissions.isEmpty
                      ? Center(
                          child: Text(
                            getEmptyMessage(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: loadMissions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredMissions.length,
                            itemBuilder: (context, index) {
                              final mission = filteredMissions[index];
                              final color = getStatusColor(mission.status);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 18),
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12000000),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 12,
                                          color: color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            getStatusLabel(mission.status),
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (mission.createdAtRelative != null &&
                                            mission
                                                .createdAtRelative!.isNotEmpty)
                                          Text(
                                            mission.createdAtRelative!,
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontSize: 14,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        mission.categoryName ?? 'Servicio',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      mission.serviceTitle ?? 'Servicio',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      mission.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF64748B),
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 18,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            getScheduleText(mission),
                                            style: const TextStyle(
                                              color: Color(0xFF475569),
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 18,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          getBudgetText(mission),
                                          style: const TextStyle(
                                            color: Color(0xFF0F172A),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                        ),
                                        onPressed: () async {
                                          if (shouldShowDetailsButton(mission)) {
                                            await goToMissionDetails(mission);
                                          } else {
                                            await goToProposals(mission);
                                          }
                                        },
                                        child: Text(
                                          getProposalButtonText(mission),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}