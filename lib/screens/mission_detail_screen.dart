import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/display_formatters.dart';
import '../models/mission_model.dart';
import '../widgets/postulation_form_sheet.dart';

class MissionDetailScreen extends StatelessWidget {
  final MissionModel mission;

  const MissionDetailScreen({
    super.key,
    required this.mission,
  });

  String _formatBudget() {
    final min = mission.priceMin ?? mission.minBudget;
    final max = mission.priceMax ?? mission.maxBudget;

    if (min != null && min > 0 && max != null && max > 0) {
      return '${formatCurrencyCop(min)} - ${formatCurrencyCop(max)}';
    }

    if (min != null && min > 0) return formatCurrencyCop(min);
    if (max != null && max > 0) return formatCurrencyCop(max);

    return 'A convenir';
  }

  String _formatLocation() {
    final address = mission.address.trim();

    if (address.isEmpty) return 'Zona por confirmar';

    if (address.toLowerCase().contains('ubicación seleccionada')) {
      return 'Ubicación seleccionada en el mapa';
    }

    return address;
  }

  String _formatDate() {
    return formatAvailabilityLabel(
      date: mission.scheduledDate ?? mission.scheduledAt,
      from: mission.scheduledFrom,
      to: mission.scheduledTo,
    );
  }

  bool get _hasMapLocation =>
      mission.latitude != null && mission.longitude != null;

  LatLng get _missionLatLng => LatLng(
        mission.latitude!,
        mission.longitude!,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: Text(
          'Detalle de la misión',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mission.categoryName != null &&
                    mission.categoryName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      mission.categoryName!,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFFF7A20),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                Text(
                  mission.serviceTitle ?? 'Servicio disponible',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  mission.description.isNotEmpty
                      ? mission.description
                      : 'Sin descripción',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Fecha',
                  value: _formatDate(),
                ),

                const SizedBox(height: 16),

                _InfoRow(
                  icon: Icons.wallet_outlined,
                  title: 'Presupuesto',
                  value: _formatBudget(),
                ),

                const SizedBox(height: 16),

                _InfoRow(
                  icon: Icons.info_outline,
                  title: 'Estado',
                  value: mission.statusLabel ?? mission.status,
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 18),

                Text(
                  'Ubicación',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFFF7A20),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _formatLocation(),
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (_hasMapLocation)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 220,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _missionLatLng,
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('mission_location'),
                            position: _missionLatLng,
                            infoWindow: InfoWindow(
                              title:
                                  mission.serviceTitle ?? 'Ubicación del servicio',
                              snippet: _formatLocation(),
                            ),
                          ),
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'No hay punto exacto en el mapa para esta misión.',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFFF7A20),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => PostulationFormSheet(serviceId: mission.id),
                );

                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Postularme a esta misión',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF7A20), size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}