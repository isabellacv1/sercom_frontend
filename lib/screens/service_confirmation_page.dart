import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/display_formatters.dart';
import '../services/auth_service.dart';
import '../services/confirmation_service.dart';
import 'review_screen.dart';



/// ServiceConfirmationPage – HU-10
///
/// Plug & Play: pásale el [serviceId], el [isWorker] flag y, si es vista
/// de Cliente, opcionalmente los datos del Trabajador ([workerName],
/// [workerPhotoUrl], [workerRating], [workerReviewCount], [totalCost]).
class ServiceConfirmationPage extends StatefulWidget {
  final String serviceId;
  final bool isWorker;

  // Datos del otro participante — los pasa quien navega a esta pantalla.
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

  bool _isLoading = false;
  bool _hasConfirmed = false;  // confiramción local optimista

  String? _currentUserName;
  // Supabase stream subscription
  late final Stream<List<Map<String, dynamic>>> _serviceStream;

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
    if (mounted) setState(() => _currentUserName = name);
  }

  // ── Confirm action ───────────────────────────────────────────────────────

  Future<void> _onConfirm() async {
    if (_isLoading || _hasConfirmed) return;
    setState(() => _isLoading = true);

    try {
      final result =
          await _confirmationService.confirmCompletion(widget.serviceId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasConfirmed = true;
      });

      final updatedService = result['service'] as Map<String, dynamic>?;
      final newStatus = updatedService?['status']?.toString() ?? '';
      if (newStatus == 'completed') {
        _navigateToReview();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.isWorker
                      ? '¡Tu confirmación fue registrada!'
                      : '¡Confirmaste el servicio!',
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _serviceStream,
      builder: (context, snapshot) {
        final row = snapshot.data?.firstOrNull;

        // Auto-navigate when both confirmed (status == 'completed')
        if (row != null) {
          final liveStatus = row['status']?.toString() ?? '';
          if (liveStatus == 'completed') {
            // Use addPostFrameCallback to avoid calling Navigator during build.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _navigateToReview();
            });
          }
        }

        final workerConfirmed = row?['worker_confirmation'] == true;
        final escrowMsg = row?['escrow_ui_message']?.toString() ??
            'Tu pago siempre se retendrá de forma segura hasta que confirmes que el trabajo fue finalizado satisfactoriamente.';

        // Determine if the current user already confirmed (merge local + live)
        final alreadyConfirmed = _hasConfirmed ||
            (widget.isWorker ? workerConfirmed : row?['client_confirmation'] == true);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0F172A), size: 20),
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

                  // ── Progress illustration ─────────────────────────────
                  _ProgressIllustration(isWorker: widget.isWorker),
                  const SizedBox(height: 32),

                  // ── Headline ─────────────────────────────────────────
                  Text(
                    'Solo nos falta tu\nconfirmación',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Live sub-headline driven by stream
                  _buildSubHeadline(workerConfirmed),
                  const SizedBox(height: 28),

                  // ── Role-specific card ────────────────────────────────
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

                  // ── Escrow banner (dynamic from stream) ──────────────
                  _EscrowBanner(message: escrowMsg),
                  const SizedBox(height: 32),

                  // ── Confirm button ────────────────────────────────────
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
                                  const Icon(Icons.verified_outlined,
                                      size: 20),
                                ],
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Contact button ───────────────────────────────────
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
                                : 'Contactar a ${widget.workerName ?? 'Isabella'}',
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

  Widget _buildSubHeadline(bool workerConfirmed) {
    final titlePart = widget.serviceTitle ?? 'luminarias';
    final namePart =
        widget.isWorker ? 'el cliente' : (widget.workerName ?? 'Isabella');

    // If the other party already confirmed, update message via stream
    final dynamic msg;
    if (workerConfirmed && !widget.isWorker) {
      msg = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.montserrat(
              fontSize: 15, color: const Color(0xFF64748B)),
          children: [
            TextSpan(
              text: widget.workerName ?? 'Isabella',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
            TextSpan(
                text: ' ha finalizado el servicio de $titlePart con éxito.'),
          ],
        ),
      );
    } else {
      msg = RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.montserrat(
              fontSize: 15, color: const Color(0xFF64748B)),
          children: [
            const TextSpan(text: '¿'),
            TextSpan(
              text: namePart,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
            TextSpan(
                text:
                    ' ha finalizado el servicio de $titlePart de manera exitosa?'),
          ],
        ),
      );
    }

    return msg as Widget;
  }
}

// ─── CHILD WIDGETS ───────────────────────────────────────────────────────────

/// Ilustración de progreso con línea y círculo central.
class _ProgressIllustration extends StatelessWidget {
  final bool isWorker;
  const _ProgressIllustration({required this.isWorker});

  @override
  Widget build(BuildContext context) {
    final accent = isWorker ? const Color(0xFFF97316) : const Color(0xFF2563EB);
    final bgLight = isWorker ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF);

    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgLight,
            ),
          ),
          // Inner ring
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.12),
            ),
          ),
          // Horizontal accent line
          Positioned(
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  accent.withOpacity(0.6),
                  accent,
                  accent.withOpacity(0.6),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          // Center icon
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
              isWorker ? Icons.check_rounded : Icons.done_all_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de Puntos de Prestigio — vista Trabajador.
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
                child: const Icon(Icons.emoji_events_outlined,
                    color: Colors.white, size: 22),
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
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 10,
              backgroundColor: const Color(0xFFFED7AA),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta con info del Trabajador — vista Cliente.
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
    final reviewLabel =
        reviewCount != null ? '($reviewCount reseñas)' : '';
    final scheduleLabel = formatAvailabilityLabel(date: scheduledAt) ;
    final costLabel = totalCost != null
        ? formatCurrencyCop(totalCost!)
        : '\$45.00';

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
          // Worker identity
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
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 16),
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
          // Schedule row
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha y Hora',
            value: scheduleLabel,
          ),
          const SizedBox(height: 14),
          // Cost row
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
  const _InfoRow({required this.icon, required this.label, required this.value});

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

/// Banner azul con mensaje de escrow dinámico.
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
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF2563EB), size: 20),
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
