import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/worker_profile_service.dart';

const _kOrange     = Color(0xFFFF7A20);
const _kOrangeLight = Color(0xFFFFF7ED);
const _kBlue       = Color(0xFF2563EB);
const _kGreen      = Color(0xFF10B981);
const _kRed        = Color(0xFFEF4444);
const _kBg         = Color(0xFFF6F7FB);
const _kTextDark   = Color(0xFF101828);
const _kTextMid    = Color(0xFF64748B);
const _kBorder     = Color(0xFFE2E8F0);
const _kWhite      = Colors.white;

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final _workerProfileService = WorkerProfileService();
  final _categoryService      = CategoryService();

  final _bioController              = TextEditingController();
  final _yearsController            = TextEditingController();
  final _portfolioTitleController   = TextEditingController();

  static const _zones = [
    {'id': 'norte',        'name': 'Norte'},
    {'id': 'nororiente',   'name': 'Nororiente'},
    {'id': 'centro',       'name': 'Centro'},
    {'id': 'oriente',      'name': 'Oriente / Aguablanca'},
    {'id': 'ladera',       'name': 'Ladera occidente'},
    {'id': 'sur',          'name': 'Sur'},
    {'id': 'suroccidente', 'name': 'Suroccidente'},
  ];

  bool _isLoading          = true;
  bool _isSaving           = false;
  bool _isPublishing       = false;
  final Map<String, bool> _uploadingItems = {};

  String _status      = 'pending_verification';
  bool   _isPublished = false;

  List<CategoryModel>          _categories = [];
  List<Map<String, dynamic>>   _portfolio  = [];
  final Set<String> _selectedCategoryIds   = {};
  final Set<String> _selectedZoneIds       = {};

  bool get _isVerified      => _status == 'verified';
  bool get _hasRequiredData => _selectedCategoryIds.isNotEmpty && _selectedZoneIds.isNotEmpty;
  bool get _anyUploading    => _uploadingItems.values.any((v) => v);
  bool get _canPublishAction =>
      _isPublished
          ? _isVerified && !_isSaving && !_isPublishing
          : _isVerified && _hasRequiredData && !_isSaving && !_isPublishing;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _yearsController.dispose();
    _portfolioTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _workerProfileService.getMyWorkerProfile(),
        _categoryService.getCategories(),
      ]);

      final profileData = results[0] as Map<String, dynamic>;
      final categories  = results[1] as List<CategoryModel>;

      final profile   = _readMap(profileData['profile']);
      final zones     = _readMapList(profileData['coverage_zones']);
      final portfolio = _readMapList(profileData['portfolio']);
      final skills    = _readMapList(profileData['skills']);

      final selectedZones = zones
          .map((z) => z['zone_id']?.toString())
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet();

      final selectedCategories = skills
          .map((s) => s['category_id']?.toString())
          .whereType<String>()
          .where((id) => id.trim().isNotEmpty)
          .toSet();

      final years = skills.isNotEmpty ? skills.first['years_experience'] : null;

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedZoneIds
          ..clear()
          ..addAll(selectedZones);
        _selectedCategoryIds
          ..clear()
          ..addAll(selectedCategories);
        _portfolio  = portfolio;
        _status     = profile['status']?.toString() ?? 'pending_verification';
        _isPublished = profile['is_published'] == true;
        _isLoading  = false;
      });

      _bioController.text   = profile['bio']?.toString() ?? '';
      _yearsController.text = years != null ? years.toString() : '';

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Error cargando perfil: $e', isError: true);
    }
  }

  Future<bool> _saveProfile({bool showMessage = true}) async {
    final bio        = _bioController.text.trim();
    final yearsText  = _yearsController.text.trim();

    if (bio.length > 1000) {
      _showMessage('La biografía no puede superar los 1000 caracteres', isError: true);
      return false;
    }
    if (_selectedCategoryIds.isEmpty) {
      _showMessage('Selecciona al menos una categoría', isError: true);
      return false;
    }
    if (_selectedZoneIds.isEmpty) {
      _showMessage('Selecciona al menos una zona de cobertura', isError: true);
      return false;
    }

    final years = yearsText.isEmpty ? null : int.tryParse(yearsText);
    if (yearsText.isNotEmpty && (years == null || years < 0)) {
      _showMessage('Los años de experiencia deben ser un número válido', isError: true);
      return false;
    }

    setState(() => _isSaving = true);

    try {
      final skills = _selectedCategoryIds.map((categoryId) => {
        'category_id': categoryId,
        if (years != null) 'years_experience': years,
      }).toList();

      await Future.wait([
        _workerProfileService.updateBio(bio),
        _workerProfileService.setCoverageZones(_selectedZoneIds.toList()),
        _workerProfileService.setWorkerSkills(skills),
      ]);

      if (showMessage) {
        _showMessage('Perfil guardado correctamente');
      }
      return true;
    } catch (e) {
      _showMessage('Error guardando perfil: $e', isError: true);
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _togglePublish() async {
    if (!_isVerified) {
      _showMessage('Tu cuenta debe estar verificada para publicar', isError: true);
      return;
    }
    if (!_isPublished && !_hasRequiredData) {
      _showMessage('Selecciona categoría y zona antes de publicar', isError: true);
      return;
    }

    final wasPublished = _isPublished;
    setState(() => _isPublishing = true);

    try {
      if (_isPublished) {
        await _workerProfileService.unpublishProfile();
      } else {
        final saved = await _saveProfile(showMessage: false);
        if (!saved) return;
        await _workerProfileService.publishProfile();
      }
      await _loadData();
      _showMessage(wasPublished ? 'Perfil despublicado' : '¡Perfil publicado!');
    } catch (e) {
      _showMessage('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _pickAndUploadPortfolio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm'],
      withData: true,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    final title = _portfolioTitleController.text.trim();

    final tempKeys = List.generate(result.files.length, (i) => 'upload_$i');

    setState(() {
      for (final k in tempKeys) {
        _uploadingItems[k] = true;
      }
    });

    _portfolioTitleController.clear();

    final uploadedItems = <Map<String, dynamic>>[];

    final futures = result.files.asMap().entries.map((entry) async {
      final idx  = entry.key;
      final file = entry.value;
      final key  = tempKeys[idx];

      try {
        final uploaded = await _workerProfileService.uploadPortfolioFile(
          file: file,
          title: result.files.length == 1 && title.isNotEmpty
              ? title
              : null,
        );

        if (uploaded != null) {
          uploadedItems.add(uploaded);
        }

      } catch (e) {
        _showMessage(
          'Error subiendo "${file.name}": $e',
          isError: true,
        );
      } finally {
        if (mounted) {
          setState(() {
            _uploadingItems.remove(key);
          });
        }
      }
    });

    await Future.wait(futures);

    if (mounted) {
      setState(() {
        _portfolio.addAll(uploadedItems);
      });
    }

    if (result.files.length > 1) {
      _showMessage('${result.files.length} archivos agregados al portafolio');
    } else {
      _showMessage('Archivo agregado al portafolio');
    }
  }

  Future<void> _deletePortfolioItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Eliminar este trabajo?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Esta acción no se puede deshacer.',
          style: GoogleFonts.montserrat(color: _kTextMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: GoogleFonts.montserrat(color: _kTextMid)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Eliminar',
                style: GoogleFonts.montserrat(
                    color: _kWhite, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _workerProfileService.removePortfolioItem(itemId);

      if (mounted) {
        setState(() {
          _portfolio.removeWhere((item) => item['id'] == itemId);
        });
      }

      _showMessage('Trabajo eliminado del portafolio');
    } catch (e) {
      _showMessage('Error eliminando: $e', isError: true);
    }
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: isError ? _kRed : _kGreen,
        behavior: SnackBarBehavior.floating,
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
        title: Text(
          'Perfil de Trabajador',
          style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w800, color: _kWhite),
        ),
        iconTheme: const IconThemeData(color: _kWhite),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kOrange))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kOrange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Categorías de trabajo'),
                    const SizedBox(height: 10),
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    _buildExperienceFields(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Zonas de cobertura'),
                    const SizedBox(height: 10),
                    _buildZoneSelector(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Biografía técnica'),
                    const SizedBox(height: 10),
                    _buildBioInput(),
                    const SizedBox(height: 24),
                    _buildPortfolioHeader(),
                    const SizedBox(height: 10),
                    _buildPortfolioUploader(),
                    const SizedBox(height: 14),
                    _buildPortfolioList(),
                    const SizedBox(height: 28),
                    _buildSaveButton(),
                    const SizedBox(height: 12),
                    _buildPublishButton(),
                    const SizedBox(height: 10),
                    _buildPublishHint(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isVerified
                      ? const Color(0xFFE8FFF3)
                      : _kOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isVerified
                      ? Icons.verified_rounded
                      : Icons.lock_clock_rounded,
                  color: _isVerified ? _kGreen : _kOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isVerified ? 'Cuenta verificada' : 'Cuenta no verificada',
                      style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isPublished ? _kGreen : _kTextMid,
                          ),
                        ),
                        Text(
                          _isPublished ? 'Perfil publicado' : 'Perfil sin publicar',
                          style: GoogleFonts.montserrat(
                              color: _kTextMid,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Completa categorías, cobertura, experiencia, bio y portafolio para aparecer ante los clientes.',
            style: GoogleFonts.montserrat(
                color: _kTextMid, height: 1.45, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w800, color: _kTextDark, fontSize: 17),
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return _buildEmptyBox('No hay categorías disponibles');
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((cat) {
        final sel = _selectedCategoryIds.contains(cat.id);
        return FilterChip(
          label: Text(cat.name),
          selected: sel,
          selectedColor: const Color(0xFFFFE4D2),
          checkmarkColor: _kOrange,
          backgroundColor: _kWhite,
          side: BorderSide(color: sel ? _kOrange : _kBorder),
          labelStyle: GoogleFonts.montserrat(
            color: sel ? const Color(0xFFB45309) : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
          onSelected: (v) => setState(() {
            v ? _selectedCategoryIds.add(cat.id) : _selectedCategoryIds.remove(cat.id);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildExperienceFields() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: TextField(
        controller: _yearsController,
        keyboardType: TextInputType.number,
        decoration: _inputDecoration(
          label: 'Años de experiencia',
          icon: Icons.timeline_rounded,
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _zones.map((zone) {
        final id  = zone['id']!;
        final sel = _selectedZoneIds.contains(id);
        return FilterChip(
          label: Text(zone['name']!),
          selected: sel,
          selectedColor: const Color(0xFFEFF6FF),
          checkmarkColor: _kBlue,
          backgroundColor: _kWhite,
          side: BorderSide(color: sel ? _kBlue : _kBorder),
          labelStyle: GoogleFonts.montserrat(
            color: sel ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
          onSelected: (v) => setState(() {
            v ? _selectedZoneIds.add(id) : _selectedZoneIds.remove(id);
          }),
        );
      }).toList(),
    );
  }

  Widget _buildBioInput() {
    return TextField(
      controller: _bioController,
      maxLength: 1000,
      maxLines: 7,
      decoration: _inputDecoration(
        label: 'Describe tu experiencia, herramientas y tipo de trabajo',
        icon: Icons.description_rounded,
      ),
    );
  }

  Widget _buildPortfolioHeader() {
    return Row(
      children: [
        Expanded(child: _buildSectionTitle('Portafolio')),
        if (_portfolio.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kOrangeLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_portfolio.length}/10',
              style: GoogleFonts.montserrat(
                  color: _kOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildPortfolioUploader() {
    final atLimit  = _portfolio.length >= 10;
    final disabled = _anyUploading || atLimit;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _portfolioTitleController,
            decoration: _inputDecoration(
              label: 'Título (opcional, aplica si subes un solo archivo)',
              icon: Icons.work_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: disabled ? null : _pickAndUploadPortfolio,
              icon: _anyUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kOrange),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                atLimit
                    ? 'Límite de 10 archivos alcanzado'
                    : _anyUploading
                        ? 'Subiendo...'
                        : 'Agregar imagen(es) o video(s)',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kOrange,
                disabledForegroundColor: _kTextMid,
                side: BorderSide(color: disabled ? _kBorder : _kOrange),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          if (!atLimit) ...[
            const SizedBox(height: 8),
            Text(
              'Puedes seleccionar varios archivos a la vez. Formatos: jpg, png, webp, mp4, mov, webm. Máx. 20 MB por archivo.',
              style: GoogleFonts.montserrat(
                  color: _kTextMid, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioList() {
    if (_portfolio.isEmpty && !_anyUploading) {
      return _buildEmptyBox('Aún no has cargado trabajos previos');
    }

    return Column(
      children: [
        ..._portfolio.map((item) => _buildPortfolioItem(item)),
        ...List.generate(
          _uploadingItems.length,
          (_) => _buildUploadingSkeleton(),
        ),
      ],
    );
  }

  Widget _buildPortfolioItem(Map<String, dynamic> item) {
    final title    = item['title']?.toString() ?? 'Trabajo previo';
    final fileType = item['file_type']?.toString() ?? 'image';
    final fileUrl  = item['file_url']?.toString() ?? '';
    final id       = item['id']?.toString() ?? '';
    final isImage  = fileType == 'image';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: fileUrl.isNotEmpty ? () => _previewImage(fileUrl, isImage) : null,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: isImage && fileUrl.isNotEmpty
                    ? Image.network(
                        fileUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null
                                ? child
                                : const Center(
                                    child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _kOrange))),
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_rounded,
                                color: _kOrange, size: 28)),
                      )
                    : const Center(
                        child: Icon(Icons.play_circle_outline_rounded,
                            color: _kOrange, size: 32)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700, color: _kTextDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isImage ? Icons.image_outlined : Icons.videocam_outlined,
                      size: 14,
                      color: _kTextMid,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isImage ? 'Imagen' : 'Video',
                      style: GoogleFonts.montserrat(
                          color: _kTextMid,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: id.isEmpty ? null : () => _deletePortfolioItem(id),
            icon: const Icon(Icons.delete_outline_rounded, color: _kRed),
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: _kOrange),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    height: 14,
                    width: 120,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 8),
                Container(
                    height: 11,
                    width: 70,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _previewImage(String url, bool isImage) {
    if (!isImage) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : () => _saveProfile(),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kTextDark,
          foregroundColor: _kWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(_kWhite)),
              )
            : Text('Guardar cambios',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _canPublishAction ? _togglePublish : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isPublished ? _kRed : _kOrange,
          disabledBackgroundColor: const Color(0xFFE5E7EB),
          foregroundColor: _kWhite,
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
        ),
        child: _isPublishing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(_kWhite)),
              )
            : Text(
                _isPublished ? 'Despublicar perfil' : 'Publicar perfil',
                style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  Widget _buildPublishHint() {
    final text = !_isVerified
        ? 'El botón se habilita cuando tu cuenta esté verificada.'
        : !_hasRequiredData
            ? 'Selecciona al menos una categoría y una zona para publicar.'
            : 'Puedes editar tu perfil publicado en cualquier momento.';
    return Text(text,
        style: GoogleFonts.montserrat(color: _kTextMid, fontSize: 13));
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Text(message,
          style: GoogleFonts.montserrat(
              color: _kTextMid, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDecoration(
      {required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kOrange),
      filled: true,
      fillColor: _kWhite,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _kOrange, width: 1.5)),
      labelStyle: GoogleFonts.montserrat(
          color: _kTextMid, fontWeight: FontWeight.w600),
    );
  }
}
