import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/certification_service.dart';
import '../services/auth_service.dart';
import 'certification_progress_screen.dart';

const _kOrange = Color(0xFFFF7A20);
const _kGreen = Color(0xFF10B981);
const _kGreenLight = Color(0xFFECFDF5);
const _kBlue = Color(0xFF2563EB);
const _kBg = Color(0xFFF6F7FB);
const _kWhite = Colors.white;
const _kTextDark = Color(0xFF101828);
const _kTextMid = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);

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

class WorkerCertificationsListScreen extends StatefulWidget {
  const WorkerCertificationsListScreen({Key? key}) : super(key: key);

  @override
  State<WorkerCertificationsListScreen> createState() =>
      _WorkerCertificationsListScreenState();
}

class _WorkerCertificationsListScreenState
    extends State<WorkerCertificationsListScreen> {
  final _service = CertificationService();

  List<CertProgressResponse>? _enrollments;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getMyEnrollments();
      setState(() {
        _enrollments = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kWhite, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mis Certificaciones',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            color: _kWhite,
            fontSize: 17,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: _kTextMid, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: _kWhite,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = _enrollments ?? [];

    if (list.isEmpty) return _buildEmpty();

    final inProgress = list
        .where((e) => e.enrollment.status == 'in_progress' ||
            e.enrollment.status == 'enrolled')
        .toList();
    final completed =
        list.where((e) => e.enrollment.status == 'completed').toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: _kOrange,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          _buildSummaryCard(
            total: list.length,
            completed: completed.length,
            inProgress: inProgress.length,
          ),
          const SizedBox(height: 28),

          if (inProgress.isNotEmpty) ...[
            _buildSectionTitle('En progreso', Icons.pending_rounded, _kOrange),
            const SizedBox(height: 12),
            ...inProgress.map((e) => _buildEnrollmentCard(e)),
            const SizedBox(height: 24),
          ],

          if (completed.isNotEmpty) ...[
            _buildSectionTitle(
                'Completadas', Icons.workspace_premium_rounded, _kGreen),
            const SizedBox(height: 12),
            ...completed.map((e) => _buildEnrollmentCard(e)),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int total,
    required int completed,
    required int inProgress,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A20), Color(0xFFFF9A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded,
              color: _kWhite, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu progreso',
                  style: GoogleFonts.montserrat(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed de $total certificaciones completadas',
                  style: GoogleFonts.montserrat(
                    color: _kWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  strokeWidth: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(_kWhite),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  total > 0
                      ? '${((completed / total) * 100).round()}%'
                      : '0%',
                  style: GoogleFonts.montserrat(
                    color: _kWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _kTextDark,
          ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentCard(CertProgressResponse item) {
    final cert = item.certification;
    final enrollment = item.enrollment;
    final meta = _metaFor(cert.category);
    final color = meta['color'] as Color;
    final icon = meta['icon'] as IconData;
    final isCompleted = enrollment.status == 'completed';
    final hasMods = enrollment.totalModules > 0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CertificationProgressScreen(
              certificationId: cert.id,
              certificationName: cert.name,
            ),
          ),
        );
        _load();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted ? _kGreen.withOpacity(0.3) : _kBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cert.name,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _buildCategoryPill(cert.category, color),
                    ],
                  ),
                ),
                isCompleted
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: _kGreenLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: _kGreen, size: 16),
                      )
                    : const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFFCBD5E1), size: 22),
              ],
            ),

            if (hasMods) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: item.progressPercent / 100,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isCompleted ? _kGreen : _kOrange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${item.progressPercent}%',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? _kGreen : _kOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${enrollment.completedModules} de ${enrollment.totalModules} módulos completados',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: _kTextMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            if (isCompleted && enrollment.completedAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      color: _kGreen, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    'Completada el ${_formatDate(enrollment.completedAt!)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: _kGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryPill(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: _kOrange.withOpacity(0.2)),
              ),
              child: const Icon(Icons.school_outlined, color: _kOrange, size: 52),
            ),
            const SizedBox(height: 24),
            Text(
              'Aún no tienes certificaciones',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: _kTextDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Inscríbete en una certificación para mejorar tu perfil y conseguir más clientes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                color: _kTextMid,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
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
