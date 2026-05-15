import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/certification_service.dart';

const _kBlue = Color(0xFF2563EB);
const _kBlueLight = Color(0xFFEFF6FF);
const _kOrange = Color(0xFFF97316);
const _kOrangeLight = Color(0xFFFFF7ED);
const _kGreen = Color(0xFF10B981);
const _kGreenLight = Color(0xFFECFDF5);
const _kTextDark = Color(0xFF0F172A);
const _kTextMid = Color(0xFF64748B);
const _kBorder = Color(0xFFE5E7EB);

const _categoryMeta = <String, Map<String, dynamic>>{
  'ética': {'icon': Icons.balance_rounded, 'color': Color(0xFF7C3AED)},
  'tecnología': {'icon': Icons.computer_rounded, 'color': _kBlue},
  'servicio al cliente': {'icon': Icons.support_agent_rounded, 'color': _kOrange},
  'seguridad': {'icon': Icons.shield_rounded, 'color': _kGreen},
  'habilidades blandas': {'icon': Icons.psychology_rounded, 'color': Color(0xFFEC4899)},
};

Map<String, dynamic> _metaFor(String category) =>
    _categoryMeta[category.toLowerCase()] ??
    {'icon': Icons.workspace_premium_rounded, 'color': _kBlue};

class WorkerCertificationsSection extends StatefulWidget {
  final String workerId;

  const WorkerCertificationsSection({Key? key, required this.workerId})
      : super(key: key);

  @override
  State<WorkerCertificationsSection> createState() =>
      _WorkerCertificationsSectionState();
}

class _WorkerCertificationsSectionState
    extends State<WorkerCertificationsSection> {
  final _service = CertificationService();
  late Future<WorkerCompletedCertsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getWorkerCompletedCertifications(widget.workerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkerCompletedCertsResponse>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        if (!data.hasCertifications) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            _buildSectionHeader(data.totalCompleted),
            const SizedBox(height: 16),
            ...data.certifications
                .map((item) => _buildCertCard(item))
                .toList(),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Certificaciones',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _kTextDark,
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _kGreenLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGreen.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, color: _kGreen, size: 14),
              const SizedBox(width: 4),
              Text(
                '$total certificado${total > 1 ? 's' : ''}',
                style: GoogleFonts.montserrat(
                  color: _kGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertCard(CompletedCertItem item) {
    final meta = _metaFor(item.certification.category);
    final color = meta['color'] as Color;
    final icon = meta['icon'] as IconData;
    final difficultyLabel = _difficultyLabel(item.certification.difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.certification.name,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPill(
                      item.certification.category,
                      color.withOpacity(0.12),
                      color,
                    ),
                    if (difficultyLabel != null) ...[
                      const SizedBox(width: 6),
                      _buildPill(
                        difficultyLabel,
                        const Color(0xFFF1F5F9),
                        _kTextMid,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: _kGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _kGreen,
                  size: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(item.completedAt),
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: _kTextMid,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Container(
          height: 20,
          width: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          2,
          (_) => Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  String? _difficultyLabel(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Básico';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return null;
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class CertificationBadge extends StatefulWidget {
  final String workerId;

  const CertificationBadge({Key? key, required this.workerId})
      : super(key: key);

  @override
  State<CertificationBadge> createState() => _CertificationBadgeState();
}

class _CertificationBadgeState extends State<CertificationBadge> {
  final _service = CertificationService();
  late Future<WorkerCompletedCertsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getWorkerCompletedCertifications(widget.workerId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WorkerCompletedCertsResponse>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasCertifications) {
          return const SizedBox.shrink();
        }
        final total = snapshot.data!.totalCompleted;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kGreenLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kGreen.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: _kGreen, size: 13),
              const SizedBox(width: 4),
              Text(
                '$total cert.',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _kGreen,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
