import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/display_formatters.dart';
import '../services/auth_service.dart';
import '../services/confirmation_service.dart';
import '../services/mission_service.dart';
import 'review_screen.dart';

/// ServiceConfirmationPage – seguimiento + confirmación
///
/// Estados soportados según DB:
/// - requested
/// - assigned
/// - on_the_way
/// - in_progress
/// - completed
/// - cancelled
/// - draft
class ServiceConfirmationPage extends StatefulWidget {
  final String serviceId;
  final bool isWorker;

  final String? workerName;
  final String? workerPhotoUrl;
  final double? workerRating;
  final int? workerReviewCount;
  final num? totalCost;
  final String? scheduledAt;
  final String? serviceTitle;

  const ServiceConfirmationPage({
    Key? key,
    required this.serviceId,
    required this.isWorker,
    this.workerName,
    this.workerPhotoUrl,
    this.workerRating,
    this.workerReviewCount,
    this.totalCost,
    this.scheduledAt,
    this.serviceTitle,
  }) : super(key: key);

  @override
  State<ServiceConfirmationPage> createState() =>
      _ServiceConfirmationPageState();
}

class _ServiceConfirmationPageState extends State<ServiceConfirmationPage> {
  final _confirmationService = ConfirmationService();
  final _authService = AuthService();
  final _missionService = MissionService();

  bool _isLoading = false;
  bool _hasConfirmed = false;
  bool _isUpdatingStatus = false;

  String? _currentUserName;
  String? _localStatusOverride;

  late final Stream<List<Map<String, dynamic>>> _serviceStream;

  static const Set<String> _workerEditableStatuses = {
    'on_the_way',
    'in_progress',
    'completed',
  };

  final List<_ServiceStatusStep> _statusSteps = const [
    _ServiceStatusStep(
      value: 'requested',
      label: 'Solicitado',
      icon: Icons.assignment_outlined,
    ),
    _ServiceStatusStep(
      value: 'assigned',
      label: 'Asignado',
      icon: Icons.person_pin_circle_outlined,
    ),
    _ServiceStatusStep(
      value: 'on_the_way',
      label: 'En camino',
      icon: Icons.directions_car_filled_outlined,
    ),
    _ServiceStatusStep(
      value: 'in_progress',
      label: 'En ejecución',
      icon: Icons.handyman_outlined,
    ),
    _ServiceStatusStep(
      value: 'completed',
      label: 'Finalizado',
      icon: Icons.check_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();

    _serviceStream = Supabase.instance.client
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('id', widget.serviceId);
  }

  Future<void> _loadCurrentUser() async {
    final name = await _authService.getUserName();

    if (mounted) {
      setState(() => _currentUserName = name);
    }
  }

 String _normalizeStatus(String? status) {
  if (status == null || status.trim().isEmpty) {
    return 'requested';
  }

  final value = status.trim().toLowerCase();

  switch (value) {
    case 'requested':
    case 'solicitado':
      return 'requested';

    case 'assigned':
    case 'asignado':
    case 'accepted':
    case 'accept':
    case 'confirmed':
    case 'confirmado':
    case 'worker_assigned':
    case 'technician_assigned':
    case 'assigned_worker':
    case 'offer_accepted':
    case 'accepted_offer':
      return 'assigned';

    case 'on_the_way':
    case 'on the way':
    case 'en_camino':
    case 'en camino':
      return 'on_the_way';

    case 'in_progress':
    case 'in progress':
    case 'en_ejecucion':
    case 'en ejecución':
    case 'en ejecucion':
      return 'in_progress';

    case 'completed':
    case 'finished':
    case 'done':
    case 'finalizado':
    case 'finalizada':
      return 'completed';

    case 'cancelled':
    case 'canceled':
    case 'cancelado':
    case 'cancelada':
      return 'cancelled';

    case 'draft':
    case 'borrador':
      return 'draft';

    default:
      return 'requested';
  }
}

String _deriveStatusFromRow(Map<String, dynamic>? row) {
  if (row == null) {
    return _normalizeStatus(_localStatusOverride);
  }

  final dbStatus = _normalizeStatus(row['status']?.toString());

  if (dbStatus != 'requested') {
    return dbStatus;
  }

  final hasAssignedWorker =
      row['worker_id'] != null ||
      row['technician_id'] != null ||
      row['assigned_worker_id'] != null ||
      row['worker_profile_id'] != null ||
      row['accepted_offer_id'] != null ||
      row['selected_offer_id'] != null ||
      row['offer_id'] != null;

  if (hasAssignedWorker) {
    return 'assigned';
  }

  return dbStatus;
}

String _resolveLiveStatus(Map<String, dynamic>? row) {
  final dbStatus = _deriveStatusFromRow(row);

  if (_localStatusOverride == null) {
    return dbStatus;
  }

  final localStatus = _normalizeStatus(_localStatusOverride);

  if (_isTerminalStatus(dbStatus)) {
    return dbStatus;
  }

  if (_getStatusIndex(localStatus) > _getStatusIndex(dbStatus)) {
    return localStatus;
  }

  return dbStatus;
}

  int _getStatusIndex(String? status) {
    final normalized = _normalizeStatus(status);

    switch (normalized) {
      case 'requested':
        return 0;
      case 'assigned':
        return 1;
      case 'on_the_way':
        return 2;
      case 'in_progress':
        return 3;
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  String _getStatusLabel(String? status) {
    final normalized = _normalizeStatus(status);

    switch (normalized) {
      case 'requested':
        return 'Solicitado';
      case 'assigned':
        return 'Asignado';
      case 'on_the_way':
        return 'En camino';
      case 'in_progress':
        return 'En ejecución';
      case 'completed':
        return 'Finalizado';
      case 'cancelled':
        return 'Cancelado';
      case 'draft':
        return 'Borrador';
      default:
        return 'Solicitado';
    }
  }

  bool _isTerminalStatus(String? status) {
    final normalized = _normalizeStatus(status);

    return normalized == 'completed' ||
        normalized == 'cancelled' ||
        normalized == 'draft';
  }

  Future<void> _updateServiceStatus(String newStatus) async {
    if (_isUpdatingStatus) return;

    if (!widget.isWorker) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo el trabajador puede actualizar el estado.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final normalizedStatus = _normalizeStatus(newStatus);

    if (!_workerEditableStatuses.contains(normalizedStatus)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            normalizedStatus == 'assigned'
                ? 'El estado Asignado se cambia cuando el cliente asigna un trabajador.'
                : 'Este estado no puede actualizarse desde seguimiento.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isUpdatingStatus = true);

    try {
      final updatedMission = await _missionService.updateMissionStatus(
        missionId: widget.serviceId,
        status: normalizedStatus,
      );

      if (!mounted) return;

      setState(() {
        _localStatusOverride = _normalizeStatus(updatedMission.status);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estado actualizado a: ${_getStatusLabel(updatedMission.status)}',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar el estado: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _goToNextStatus(String? currentStatus) async {
    if (_isTerminalStatus(currentStatus)) return;

    final normalized = _normalizeStatus(currentStatus);

    if (normalized == 'requested') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero el cliente debe asignar un trabajador para iniciar el seguimiento.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentIndex = _getStatusIndex(normalized);

    if (currentIndex >= _statusSteps.length - 1) return;

    final nextStatus = _statusSteps[currentIndex + 1].value;

    if (nextStatus == 'assigned') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El estado Asignado no se cambia desde seguimiento.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await _updateServiceStatus(nextStatus);
  }

Future<void> _onConfirm() async {
  if (_isLoading || _hasConfirmed) return;

  setState(() => _isLoading = true);

  try {
    final result =
        await _confirmationService.confirmCompletion(widget.serviceId);

    if (!mounted) return;

    final rawService = result['service'];
    final updatedService = rawService is Map
        ? Map<String, dynamic>.from(rawService)
        : <String, dynamic>{};

    final clientConfirmed = updatedService['client_confirmation'] == true;
    final workerConfirmed = updatedService['worker_confirmation'] == true;

    final currentUserConfirmed =
        widget.isWorker ? workerConfirmed : clientConfirmed;

    setState(() {
      _isLoading = false;
      _hasConfirmed = currentUserConfirmed;
    });

    if (clientConfirmed && workerConfirmed) {
      _navigateToReview();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.isWorker
                    ? 'Tu confirmación fue registrada. Falta la confirmación del cliente.'
                    : 'Tu confirmación fue registrada. Falta la confirmación del trabajador.',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error al confirmar: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  void _navigateToReview() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(serviceId: widget.serviceId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _serviceStream,
      builder: (context, snapshot) {
        final row = snapshot.data != null && snapshot.data!.isNotEmpty
            ? snapshot.data!.first
            : null;

final liveStatus = _resolveLiveStatus(row);

        if (row != null && liveStatus == 'completed') {
          final clientConfirmed = row['client_confirmation'] == true;
          final workerConfirmed = row['worker_confirmation'] == true;

          if (clientConfirmed && workerConfirmed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _navigateToReview();
            });
          }
        }

        final workerConfirmed = row?['worker_confirmation'] == true;
        final clientConfirmed = row?['client_confirmation'] == true;

        final escrowMsg = row?['escrow_ui_message']?.toString() ??
            'Tu pago siempre se retendrá de forma segura hasta que confirmes que el trabajo fue finalizado satisfactoriamente.';

        final alreadyConfirmed = _hasConfirmed ||
            (widget.isWorker ? workerConfirmed : clientConfirmed);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  _ProgressIllustration(
                    isWorker: widget.isWorker,
                    currentStatus: liveStatus,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Seguimiento del\nservicio',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isWorker
                        ? 'Actualiza el estado del servicio para que el cliente pueda ver el avance en tiempo real.'
                        : 'Aquí puedes ver en qué etapa se encuentra tu servicio en todo momento.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ServiceTrackingCard(
                    currentStatus: liveStatus,
                    statusSteps: _statusSteps,
                    isWorker: widget.isWorker,
                    isUpdating: _isUpdatingStatus,
                    onNextStatus: () => _goToNextStatus(liveStatus),
                    onSelectStatus: _updateServiceStatus,
                    getStatusIndex: _getStatusIndex,
                    getStatusLabel: _getStatusLabel,
                    isTerminalStatus: _isTerminalStatus,
                  ),
                  const SizedBox(height: 24),
                  if (widget.isWorker)
                    _PrestigeCard(userName: _currentUserName)
                  else
                    _WorkerInfoCard(
                      name: widget.workerName ?? 'Trabajador',
                      photoUrl: widget.workerPhotoUrl,
                      rating: widget.workerRating,
                      reviewCount: widget.workerReviewCount,
                      scheduledAt: widget.scheduledAt,
                      totalCost: widget.totalCost,
                    ),
                  const SizedBox(height: 20),
                  _EscrowBanner(message: escrowMsg),
                  const SizedBox(height: 28),
                  if (liveStatus == 'completed') ...[
                    _buildFinalConfirmationSection(
                      alreadyConfirmed: alreadyConfirmed,
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isWorker
                                ? 'Contactar al cliente'
                                : 'Contactar a ${widget.workerName ?? 'trabajador'}',
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('😊'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinalConfirmationSection({
    required bool alreadyConfirmed,
  }) {
    return Column(
      children: [
        Text(
          'El servicio ya está marcado como finalizado. Ahora puedes confirmar para cerrar el proceso.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: alreadyConfirmed ? null : _onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFF94A3B8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        alreadyConfirmed
                            ? 'Confirmado ✓'
                            : 'Confirmar Trabajo',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!alreadyConfirmed) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.verified_outlined, size: 20),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ServiceStatusStep {
  final String value;
  final String label;
  final IconData icon;

  const _ServiceStatusStep({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class _ServiceTrackingCard extends StatelessWidget {
  final String currentStatus;
  final List<_ServiceStatusStep> statusSteps;
  final bool isWorker;
  final bool isUpdating;
  final VoidCallback onNextStatus;
  final Future<void> Function(String status) onSelectStatus;
  final int Function(String? status) getStatusIndex;
  final String Function(String? status) getStatusLabel;
  final bool Function(String? status) isTerminalStatus;

  const _ServiceTrackingCard({
    required this.currentStatus,
    required this.statusSteps,
    required this.isWorker,
    required this.isUpdating,
    required this.onNextStatus,
    required this.onSelectStatus,
    required this.getStatusIndex,
    required this.getStatusLabel,
    required this.isTerminalStatus,
  });

  @override
  Widget build(BuildContext context) {
    final currentIndex = getStatusIndex(currentStatus);
    final isCompletedFlow = currentStatus == 'completed';
    final isSpecialTerminal =
        currentStatus == 'cancelled' || currentStatus == 'draft';

    final workerEditableSteps = statusSteps
        .where(
          (step) =>
              step.value == 'on_the_way' ||
              step.value == 'in_progress' ||
              step.value == 'completed',
        )
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _statusIcon(currentStatus),
                  color: _statusColor(currentStatus),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estado actual',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      getStatusLabel(currentStatus),
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (!isSpecialTerminal) ...[
            Column(
              children: List.generate(statusSteps.length, (index) {
                final step = statusSteps[index];
                final isCompleted = index <= currentIndex;
                final isCurrent = index == currentIndex;

                return _TrackingStepItem(
                  step: step,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  showLine: index != statusSteps.length - 1,
                );
              }),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: currentStatus == 'cancelled'
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: currentStatus == 'cancelled'
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Text(
                currentStatus == 'cancelled'
                    ? 'Este servicio fue cancelado.'
                    : 'Este servicio está en borrador.',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: currentStatus == 'cancelled'
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
          if (isWorker && !isSpecialTerminal) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isCompletedFlow || isUpdating ? null : onNextStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFF94A3B8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isCompletedFlow
                            ? 'Servicio finalizado'
                            : 'Avanzar estado',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: workerEditableSteps.map((step) {
                final selected = step.value == currentStatus;
                final stepIndex = getStatusIndex(step.value);
                final canSelect = !isUpdating &&
                    !selected &&
                    !isCompletedFlow &&
                    stepIndex == currentIndex + 1;

                return ChoiceChip(
                  selected: selected,
                  label: Text(
                    step.label,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          selected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                  selectedColor: const Color(0xFF2563EB),
                  backgroundColor: Colors.white,
                  disabledColor: const Color(0xFFF1F5F9),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  onSelected: canSelect ? (_) => onSelectStatus(step.value) : null,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static IconData _statusIcon(String? status) {
    switch (status) {
      case 'requested':
        return Icons.assignment_outlined;
      case 'assigned':
        return Icons.person_pin_circle_outlined;
      case 'on_the_way':
        return Icons.directions_car_filled_outlined;
      case 'in_progress':
        return Icons.handyman_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'draft':
        return Icons.edit_note_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  static Color _statusColor(String? status) {
    switch (status) {
      case 'cancelled':
        return const Color(0xFFDC2626);
      case 'draft':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF2563EB);
    }
  }
}

class _TrackingStepItem extends StatelessWidget {
  final _ServiceStatusStep step;
  final bool isCompleted;
  final bool isCurrent;
  final bool showLine;

  const _TrackingStepItem({
    required this.step,
    required this.isCompleted,
    required this.isCurrent,
    required this.showLine,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCompleted ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF2563EB) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : step.icon,
                color: isCompleted ? Colors.white : const Color(0xFF94A3B8),
                size: 18,
              ),
            ),
            if (showLine)
              Container(
                width: 2,
                height: 34,
                color: color.withOpacity(0.4),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              step.label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCompleted
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressIllustration extends StatelessWidget {
  final bool isWorker;
  final String currentStatus;

  const _ProgressIllustration({
    required this.isWorker,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    final accent = currentStatus == 'cancelled'
        ? const Color(0xFFDC2626)
        : isWorker
            ? const Color(0xFFF97316)
            : const Color(0xFF2563EB);

    final bgLight = currentStatus == 'cancelled'
        ? const Color(0xFFFEF2F2)
        : isWorker
            ? const Color(0xFFFFF7ED)
            : const Color(0xFFEFF6FF);

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgLight,
            ),
          ),
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withOpacity(0.6),
                    accent,
                    accent.withOpacity(0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _iconForStatus(currentStatus),
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForStatus(String? status) {
    switch (status) {
      case 'requested':
        return Icons.assignment_outlined;
      case 'assigned':
        return Icons.person_pin_circle_outlined;
      case 'on_the_way':
        return Icons.directions_car_filled_outlined;
      case 'in_progress':
        return Icons.handyman_outlined;
      case 'completed':
        return Icons.check_rounded;
      case 'cancelled':
        return Icons.close_rounded;
      case 'draft':
        return Icons.edit_note_outlined;
      default:
        return Icons.track_changes_rounded;
    }
  }
}

class _PrestigeCard extends StatelessWidget {
  final String? userName;

  const _PrestigeCard({this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '¡Ánimate! Entre más servicios exitosos realices conseguirás más Puntos de Prestigio',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFFC2410C),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nivel Actual',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Próximo Rango',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: const Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(
              value: 0.65,
              minHeight: 10,
              backgroundColor: Color(0xFFFED7AA),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerInfoCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double? rating;
  final int? reviewCount;
  final String? scheduledAt;
  final num? totalCost;

  const _WorkerInfoCard({
    required this.name,
    this.photoUrl,
    this.rating,
    this.reviewCount,
    this.scheduledAt,
    this.totalCost,
  });

  @override
  Widget build(BuildContext context) {
    final ratingLabel = rating != null ? rating!.toStringAsFixed(1) : '—';
    final reviewLabel = reviewCount != null ? '($reviewCount reseñas)' : '';
    final scheduleLabel = formatAvailabilityLabel(date: scheduledAt);
    final costLabel =
        totalCost != null ? formatCurrencyCop(totalCost!) : '\$45.00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? const Icon(Icons.person, size: 28, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$ratingLabel $reviewLabel',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9)),
          ),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha y Hora',
            value: scheduleLabel,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Costo Total',
            value: '$costLabel  (Incluye comisión)',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EscrowBanner extends StatelessWidget {
  final String message;

  const _EscrowBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                color: const Color(0xFF1E3A8A),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}