import 'package:flutter/material.dart';
import '../models/mission_model.dart';
import '../services/mission_service.dart';
import 'candidate_list_screen.dart';

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
        isLoading = false;
      });
    }
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Buscando trabajadores';
      case 'receiving_offers':
        return 'Recibiendo postulaciones';
      case 'confirmed':
        return 'Confirmada';
      case 'in_progress':
        return 'En curso';
      case 'finished':
        return 'Finalizada';
      default:
        return status;
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFEAB308);
      case 'receiving_offers':
        return const Color(0xFF2563EB);
      case 'confirmed':
        return const Color(0xFF22C55E);
      case 'in_progress':
        return const Color(0xFF6366F1);
      case 'finished':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  List<MissionModel> get filteredMissions {
    if (selectedTab == 0) {
      return missions
          .where((m) => m.status != 'finished' && m.status != 'in_progress')
          .toList();
    }
    if (selectedTab == 1) {
      return missions.where((m) => m.status == 'in_progress').toList();
    }
    return missions.where((m) => m.status == 'finished').toList();
  }

  String getBudgetText(MissionModel mission) {
    final min = mission.minBudget ?? 0;
    final max = mission.maxBudget ?? 0;

    if (min > 0 && max > 0) {
      return '\$$min - \$$max';
    }

    if (min > 0) {
      return '\$$min';
    }

    if (max > 0) {
      return '\$$max';
    }

    return 'A convenir';
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
                      Expanded(
                        child: Text(
                          'Mis Misiones',
                          style: const TextStyle(
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
                      ? const Center(
                          child: Text(
                            'No tienes misiones publicadas',
                            style: TextStyle(fontSize: 16),
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
                                        const Text(
                                          'Hace 2 horas',
                                          style: TextStyle(
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
                                        const Icon(Icons.calendar_today_outlined,
                                            size: 18, color: Color(0xFF2563EB)),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'Para hoy',
                                            style: TextStyle(
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
                                          backgroundColor: const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CandidateListScreen(
                                                serviceId: mission.id,
                                                mission: mission,
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Ver propuestas',
                                          style: TextStyle(
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