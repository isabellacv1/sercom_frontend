import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/certification_service.dart';

const _kBlue = Color(0xFF2563EB);
const _kOrange = Color(0xFFFF7A20);
const _kGreen = Color(0xFF10B981);
const _kGreenLight = Color(0xFFECFDF5);
const _kBg = Color(0xFFF6F7FB);
const _kTextDark = Color(0xFF101828);
const _kTextMid = Color(0xFF64748B);
const _kBorder = Color(0xFFE2E8F0);
const _kWhite = Colors.white;

class CertificationProgressScreen extends StatefulWidget {
  final String certificationId;
  final String certificationName;

  const CertificationProgressScreen({
    Key? key,
    required this.certificationId,
    required this.certificationName,
  }) : super(key: key);

  @override
  State<CertificationProgressScreen> createState() =>
      _CertificationProgressScreenState();
}

class _CertificationProgressScreenState
    extends State<CertificationProgressScreen>
    with SingleTickerProviderStateMixin {
  final _service = CertificationService();

  CertProgressResponse? _data;
  bool _isLoading = true;
  String? _error;
  String? _completingModuleId;

  late final AnimationController _progressAnimController;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progressAnim = const AlwaysStoppedAnimation(0.0);
    _loadProgress();
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _service.getMyProgress(widget.certificationId);
      _animateProgress(data.progressPercent / 100.0);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _animateProgress(double to) {
    final from = _progressAnim.value;
    _progressAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(
        parent: _progressAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _progressAnimController
      ..reset()
      ..forward();
  }

  Future<void> _completeModule(String moduleId) async {
    setState(() => _completingModuleId = moduleId);
    try {
      final updated =
          await _service.completeModule(widget.certificationId, moduleId);
      _animateProgress(updated.progressPercent / 100.0);
      setState(() {
        _data = updated;
        _completingModuleId = null;
      });

      if (updated.enrollment.status == 'completed' && mounted) {
        _showCompletionDialog();
      }
    } catch (e) {
      setState(() => _completingModuleId = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: _kGreenLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: _kGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Certificación completada!',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _kTextDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Has completado todos los módulos de "${widget.certificationName}". Esta certificación ya aparece en tu perfil.',
                style: GoogleFonts.montserrat(
                  color: _kTextMid,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  child: Text(
                    '¡Genial!',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w800,
                      color: _kWhite,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          widget.certificationName,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            color: _kWhite,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kOrange),
      );
    }

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
                style: GoogleFonts.montserrat(color: _kTextMid),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProgress,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    foregroundColor: _kWhite,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ],
          ),
        ),
      );
    }

    final data = _data!;

    return RefreshIndicator(
      onRefresh: _loadProgress,
      color: _kOrange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressCard(data),
            const SizedBox(height: 24),
            _buildModulesSection(data),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(CertProgressResponse data) {
    final statusInfo = _statusInfo(data.enrollment.status);
    final hasMods = data.modules.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPill(
                data.certification.category,
                _kBlue.withOpacity(0.1),
                _kBlue,
              ),
              if (data.certification.difficulty != null) ...[
                const SizedBox(width: 8),
                _buildPill(
                  _diffLabel(data.certification.difficulty),
                  const Color(0xFFF1F5F9),
                  _kTextMid,
                ),
              ],
            ],
          ),
          const SizedBox(height: 24),

          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, _) {
              final pct = _progressAnim.value;
              return SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: hasMods ? pct : null,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          data.enrollment.status == 'completed'
                              ? _kGreen
                              : _kOrange,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasMods
                              ? '${(pct * 100).round()}%'
                              : '—',
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _kTextDark,
                          ),
                        ),
                        Text(
                          'completado',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            color: _kTextMid,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: statusInfo['bg'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusInfo['icon'] as IconData,
                  color: statusInfo['fg'] as Color,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  statusInfo['label'] as String,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: statusInfo['fg'] as Color,
                  ),
                ),
              ],
            ),
          ),

          if (hasMods) ...[
            const SizedBox(height: 20),
            // Contadores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(
                  '${data.enrollment.completedModules}',
                  'completados',
                  _kGreen,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: _kBorder,
                ),
                _buildStat(
                  '${data.enrollment.totalModules - data.enrollment.completedModules}',
                  'pendientes',
                  _kOrange,
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: _kBorder,
                ),
                _buildStat(
                  '${data.enrollment.totalModules}',
                  'total',
                  _kTextMid,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: _kTextMid,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildModulesSection(CertProgressResponse data) {
    if (data.modules.isEmpty) {
      return _buildNoModulesCard(data.enrollment.status);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Módulos del curso',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: _kTextDark,
          ),
        ),
        const SizedBox(height: 14),
        ...data.modules.asMap().entries.map(
          (entry) => _buildModuleCard(
            module: entry.value,
            index: entry.key,
            isLast: entry.key == data.modules.length - 1,
            certCompleted: data.enrollment.status == 'completed',
          ),
        ),
      ],
    );
  }

  Widget _buildModuleCard({
    required ModuleWithProgress module,
    required int index,
    required bool isLast,
    required bool certCompleted,
  }) {
    final isCompleting = _completingModuleId == module.id;
    final canComplete = !module.isCompleted && !certCompleted && !isCompleting;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _buildTimelineDot(module.isCompleted),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: module.isCompleted
                          ? _kGreen.withOpacity(0.4)
                          : _kBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: module.isCompleted
                      ? _kGreen.withOpacity(0.3)
                      : _kBorder,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Módulo ${index + 1}: ${module.title}',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kTextDark,
                          ),
                        ),
                      ),
                      if (module.isCompleted)
                        const Icon(Icons.check_circle_rounded,
                            color: _kGreen, size: 20),
                    ],
                  ),
                  if (module.description != null &&
                      module.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      module.description!,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        color: _kTextMid,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (module.isCompleted && module.completedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Completado el ${_formatDate(module.completedAt!)}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: _kGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (canComplete) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _completeModule(module.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kOrange,
                          foregroundColor: _kWhite,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Marcar como completado',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (isCompleting) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _kOrange,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDot(bool completed) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: completed ? _kGreen : _kWhite,
        border: Border.all(
          color: completed ? _kGreen : _kBorder,
          width: 2,
        ),
      ),
      child: completed
          ? const Icon(Icons.check_rounded, color: _kWhite, size: 16)
          : null,
    );
  }

  Widget _buildNoModulesCard(String status) {
    final isCompleted = status == 'completed';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Icon(
            isCompleted
                ? Icons.workspace_premium_rounded
                : Icons.info_outline_rounded,
            color: isCompleted ? _kGreen : _kTextMid,
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            isCompleted
                ? 'Certificación obtenida'
                : 'Esta certificación no tiene módulos definidos.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: _kTextMid,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'completed':
        return {
          'label': 'Certificación completada',
          'icon': Icons.workspace_premium_rounded,
          'bg': _kGreenLight,
          'fg': _kGreen,
        };
      case 'in_progress':
        return {
          'label': 'En progreso',
          'icon': Icons.pending_rounded,
          'bg': const Color(0xFFFFF7ED),
          'fg': _kOrange,
        };
      default:
        return {
          'label': 'Inscrito',
          'icon': Icons.school_outlined,
          'bg': const Color(0xFFEFF6FF),
          'fg': _kBlue,
        };
    }
  }

  String _diffLabel(String? difficulty) {
    switch (difficulty) {
      case 'beginner':
        return 'Básico';
      case 'intermediate':
        return 'Intermedio';
      case 'advanced':
        return 'Avanzado';
      default:
        return '';
    }
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'ago',
        'sep', 'oct', 'nov', 'dic'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
