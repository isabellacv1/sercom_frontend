import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../core/display_formatters.dart';
import '../services/proposal_service.dart';

class PostulationsScreen extends StatefulWidget {
  const PostulationsScreen({Key? key}) : super(key: key);

  @override
  State<PostulationsScreen> createState() => _PostulationsScreenState();
}

class _PostulationsScreenState extends State<PostulationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = ProposalService();

  late Future<List<Map<String, dynamic>>> _pendingFuture;
  late Future<List<Map<String, dynamic>>> _acceptedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Optional: refresh data on tab change if needed
      }
    });
    _refresh();
  }

  void _refresh() {
    setState(() {
      _pendingFuture = _service.getMyProposals(status: 'pending');
      _acceptedFuture = _service.getMyProposals(status: 'accepted');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTab(_pendingFuture, 'pending'),
                  _buildTab(_acceptedFuture, 'accepted'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ───────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Postulaciones',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 24,
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
    );
  }

  // ─── CUSTOM PILL TAB BAR ────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(32),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'En espera'),
          Tab(text: 'Aceptadas'),
        ],
      ),
    );
  }

  // ─── TAB CONTENT ───────────────────────────────────────────────────────────
  Widget _buildTab(Future<List<Map<String, dynamic>>> future, String status) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(children: [
            _statusBanner(status, hasData: false),
            _buildShimmerList(),
          ]);
        }

        if (snapshot.hasError) {
          return ListView(children: [
            _statusBanner(status, hasData: false),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'No se pudo cargar las postulaciones.\nIntenta más tarde.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    color: const Color(0xFF64748B), fontSize: 15),
              ),
            ),
          ]);
        }

        final proposals = snapshot.data ?? [];

        if (proposals.isEmpty) {
          return ListView(children: [
            _statusBanner(status, hasData: false),
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 60,
                      color: const Color(0xFF94A3B8).withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    status == 'pending'
                        ? 'Aún no tienes postulaciones\nen espera.'
                        : 'Todavía no has sido\nseleccionado para una misión.',
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
          itemCount: proposals.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) return _statusBanner(status, hasData: true);
            return _proposalCard(proposals[index - 1], status);
          },
        );
      },
    );
  }

  // ─── STATUS BANNER (PROGRAMMATIC) ───────────────────────────────────────────
  Widget _statusBanner(String status, {required bool hasData}) {
    if (!hasData) return const SizedBox(height: 8);

    final isPending = status == 'pending';
    final bgColor = isPending ? const Color(0xFFFFFBEB) : const Color(0xFFFFF3E0);
    final iconColor = isPending ? const Color(0xFFFF7A20) : const Color(0xFF10B981);
    final title = isPending ? 'Dale un momento a tu cliente' : '¡Felicidades has sido elegido!';
    final subtitle = isPending 
        ? 'Estamos procesando tu postulación, pronto recibirás noticias.' 
        : 'Tu cliente está ansioso de que le colabores, ¡ánimo!';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: iconColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: isPending ? const Color(0xFF64748B) : iconColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isPending ? Icons.chat_bubble_outline : Icons.verified_user_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROPOSAL CARD ─────────────────────────────────────────────────────────
  Widget _proposalCard(Map<String, dynamic> p, String status) {
    final createdAtRelative = readStringValue(
          p,
          ['created_at_relative', 'createdAtRelative'],
        ) ??
        '';
    final categoryName = readStringValue(p, ['category_name', 'categoryName']);
    final serviceTitle = readStringValue(p, ['service_title', 'serviceTitle', 'title']);
    final description = readStringValue(p, ['description']);
    final priceMin = readValue(p, ['price_min', 'priceMin', 'min_budget', 'budget_min']);
    final priceMax = readValue(p, ['price_max', 'priceMax', 'max_budget', 'budget_max']);
    final isAccepted = status == 'accepted';
    final scheduleText = formatAvailabilityLabel(
      date: readStringValue(
        p,
        [
          'scheduled_date',
          'scheduledDate',
          'available_date',
          'availableDate',
          'service_date',
          'serviceDate',
          'requested_date',
          'requestedDate',
        ],
      ),
      from: readStringValue(
        p,
        ['scheduled_from', 'scheduledFrom', 'available_from', 'availableFrom'],
      ),
      to: readStringValue(
        p,
        ['scheduled_to', 'scheduledTo', 'available_to', 'availableTo'],
      ),
    );

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
          // Dynamic Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isAccepted 
                      ? const Color(0xFF10B981).withOpacity(0.1) 
                      : const Color(0xFFFF7A20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isAccepted ? const Color(0xFF10B981) : const Color(0xFFFF7A20),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAccepted ? '¡Seleccionado!' : 'Tu postulación está en revisión',
                      style: GoogleFonts.montserrat(
                        color: isAccepted ? const Color(0xFF10B981) : const Color(0xFFFF7A20),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (createdAtRelative.isNotEmpty)
                Text(
                  createdAtRelative,
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Category badge
          if (categoryName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFFF7A20), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    categoryName,
                    style: GoogleFonts.montserrat(
                      color: const Color(0xFFFF7A20),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          if (categoryName != null) const SizedBox(height: 12),

          // Title
          if (serviceTitle != null)
            Text(
              serviceTitle,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),

          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 14),

          // Info row
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: Color(0xFFFF7A20), size: 18),
              const SizedBox(width: 8),
              Text(
                scheduleText,
                style: GoogleFonts.montserrat(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (priceMin != null || priceMax != null) ...[
                const SizedBox(width: 24),
                const Icon(Icons.wallet_outlined, color: Color(0xFFFF7A20), size: 18),
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

          // Footer
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7A20),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Detalles de la Misión',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────


  String _formatBudget(dynamic min, dynamic max) {
    final iMin = min is int ? min : (min is num ? min.toInt() : null);
    final iMax = max is int ? max : (max is num ? max.toInt() : null);
    if (iMin == null && iMax == null) return '';
    final fMin = iMin != null ? formatCurrencyCop(iMin) : '';
    final fMax = iMax != null ? formatCurrencyCop(iMax) : '';
    if (fMin.isNotEmpty && fMax.isNotEmpty) return '$fMin - $fMax';
    return fMin.isNotEmpty ? fMin : fMax;
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
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
      ),
    );
  }
}
