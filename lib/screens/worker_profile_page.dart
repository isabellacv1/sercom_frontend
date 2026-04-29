import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category_model.dart';
import '../services/category_service.dart';
import '../services/worker_profile_service.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final WorkerProfileService _workerProfileService = WorkerProfileService();
  final CategoryService _categoryService = CategoryService();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _yearsController = TextEditingController();
  final TextEditingController _basePriceController = TextEditingController();
  final TextEditingController _portfolioTitleController = TextEditingController();

  final List<Map<String, String>> _zones = const [
    {'id': 'norte', 'name': 'Norte'},
    {'id': 'nororiente', 'name': 'Nororiente'},
    {'id': 'centro', 'name': 'Centro'},
    {'id': 'oriente', 'name': 'Oriente / Aguablanca'},
    {'id': 'ladera', 'name': 'Ladera occidente'},
    {'id': 'sur', 'name': 'Sur'},
    {'id': 'suroccidente', 'name': 'Suroccidente'},
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPublishing = false;
  bool _isUploadingPortfolio = false;
  String _status = 'pending_verification';
  bool _isPublished = false;
  List<CategoryModel> _categories = [];
  List<Map<String, dynamic>> _portfolio = [];
  final Set<String> _selectedCategoryIds = <String>{};
  final Set<String> _selectedZoneIds = <String>{};

  bool get _isVerified => _status == 'verified';
  bool get _hasRequiredData => _selectedCategoryIds.isNotEmpty && _selectedZoneIds.isNotEmpty;
  bool get _canPublishAction => _isPublished
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
    _basePriceController.dispose();
    _portfolioTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        _workerProfileService.getMyWorkerProfile(),
        _categoryService.getCategories(),
      ]);

      final profileData = results[0] as Map<String, dynamic>;
      final categories = results[1] as List<CategoryModel>;
      final profile = _readMap(profileData['profile']);
      final zones = _readMapList(profileData['coverage_zones']);
      final portfolio = _readMapList(profileData['portfolio']);
      final skills = _readMapList(profileData['skills']);
      final selectedZones = zones
          .map((zone) => zone['zone_id']?.toString())
          .whereType<String>()
          .where((zoneId) => zoneId.trim().isNotEmpty)
          .toSet();
      final selectedCategories = skills
          .map((skill) => skill['category_id']?.toString())
          .whereType<String>()
          .where((categoryId) => categoryId.trim().isNotEmpty)
          .toSet();

      if (skills.isNotEmpty) {
        final firstSkill = skills.first;
        final years = firstSkill['years_experience'];
        final basePrice = firstSkill['base_price'];

        if (years != null) {
          _yearsController.text = years.toString();
        }

        if (basePrice != null) {
          _basePriceController.text = basePrice.toString();
        }
      }

      _bioController.text = profile['bio']?.toString() ?? '';

      if (!mounted) return;

      setState(() {
        _categories = categories;
        _selectedZoneIds
          ..clear()
          ..addAll(selectedZones);
        _selectedCategoryIds
          ..clear()
          ..addAll(selectedCategories);
        _portfolio = portfolio;
        _status = profile['status']?.toString() ?? 'pending_verification';
        _isPublished = profile['is_published'] == true;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage('Error cargando perfil de trabajador: $e', isError: true);
    }
  }

  Future<bool> _saveProfile({bool showMessage = true}) async {
    final bio = _bioController.text.trim();
    final yearsText = _yearsController.text.trim();
    final basePriceText = _basePriceController.text.trim();

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
    final basePrice = basePriceText.isEmpty ? null : num.tryParse(basePriceText);

    if (yearsText.isNotEmpty && (years == null || years < 0)) {
      _showMessage('Los años de experiencia deben ser un número válido', isError: true);
      return false;
    }

    if (basePriceText.isNotEmpty && (basePrice == null || basePrice < 0)) {
      _showMessage('La tarifa base debe ser un número válido', isError: true);
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final skills = _selectedCategoryIds.map((categoryId) {
        return {
          'category_id': categoryId,
          if (years != null) 'years_experience': years,
          if (basePrice != null) 'base_price': basePrice,
        };
      }).toList();

      await _workerProfileService.updateBio(bio);
      await _workerProfileService.setCoverageZones(_selectedZoneIds.toList());
      await _workerProfileService.setWorkerSkills(skills);
      await _loadData();

      if (showMessage) {
        _showMessage('Perfil de trabajador guardado');
      }

      return true;
    } catch (e) {
      _showMessage('Error guardando perfil: $e', isError: true);
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _togglePublish() async {
    if (!_isVerified) {
      _showMessage('Tu cuenta debe estar verificada para publicar el perfil', isError: true);
      return;
    }

    if (!_isPublished && !_hasRequiredData) {
      _showMessage('Selecciona al menos una categoría y una zona de cobertura', isError: true);
      return;
    }

    final wasPublished = _isPublished;

    setState(() {
      _isPublishing = true;
    });

    try {
      if (_isPublished) {
        await _workerProfileService.unpublishProfile();
      } else {
        final saved = await _saveProfile(showMessage: false);

        if (!saved) return;

        await _workerProfileService.publishProfile();
      }

      await _loadData();
      _showMessage(wasPublished ? 'Perfil despublicado' : 'Perfil publicado');
    } catch (e) {
      _showMessage('Error publicando perfil: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPortfolio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov', 'webm'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _isUploadingPortfolio = true;
    });

    try {
      await _workerProfileService.uploadPortfolioFile(
        file: result.files.first,
        title: _portfolioTitleController.text.trim(),
      );
      _portfolioTitleController.clear();
      await _loadData();
      _showMessage('Trabajo agregado al portafolio');
    } catch (e) {
      _showMessage('Error subiendo portafolio: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPortfolio = false;
        });
      }
    }
  }

  Future<void> _deletePortfolioItem(String itemId) async {
    try {
      await _workerProfileService.removePortfolioItem(itemId);
      await _loadData();
      _showMessage('Item eliminado del portafolio');
    } catch (e) {
      _showMessage('Error eliminando item: $e', isError: true);
    }
  }

  Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _readMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceAll('Exception: ', '')),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF6F7FB);
    const orangeColor = Color(0xFFFF7A20);
    const textDark = Color(0xFF101828);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: orangeColor,
        elevation: 0,
        title: Text(
          'Perfil de Trabajador',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Categorías de trabajo'),
                    const SizedBox(height: 10),
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    _buildExperienceFields(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Zonas de cobertura'),
                    const SizedBox(height: 10),
                    _buildZoneSelector(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Biografía técnica'),
                    const SizedBox(height: 10),
                    _buildBioInput(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Portafolio'),
                    const SizedBox(height: 10),
                    _buildPortfolioUploader(),
                    const SizedBox(height: 14),
                    _buildPortfolioList(),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : () => _saveProfile(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: textDark,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Guardar cambios',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canPublishAction ? _togglePublish : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPublished ? const Color(0xFFEF4444) : orangeColor,
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: const Color(0xFF94A3B8),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isPublishing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                _isPublished ? 'Despublicar perfil' : 'Publicar perfil',
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      !_isVerified
                          ? 'El botón se habilita cuando tu cuenta esté verificada.'
                          : !_hasRequiredData
                              ? 'Selecciona al menos una categoría y una zona para publicar.'
                              : 'Puedes editar tu perfil publicado en cualquier momento.',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final statusLabel = _isVerified ? 'Cuenta verificada' : 'Cuenta no verificada';
    final publishLabel = _isPublished ? 'Perfil publicado' : 'Perfil sin publicar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isVerified ? const Color(0xFFE8FFF3) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isVerified ? Icons.verified_rounded : Icons.lock_clock_rounded,
                  color: _isVerified ? const Color(0xFF10B981) : const Color(0xFFFF7A20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      publishLabel,
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Completa tus categorías, cobertura, experiencia, biografía y portafolio para aparecer ante los clientes.',
            style: GoogleFonts.montserrat(
              color: const Color(0xFF64748B),
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF101828),
        fontSize: 17,
      ),
    );
  }

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return _buildEmptyBox('No hay categorías activas disponibles');
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _categories.map((category) {
        final selected = _selectedCategoryIds.contains(category.id);

        return FilterChip(
          label: Text(category.name),
          selected: selected,
          selectedColor: const Color(0xFFFFE4D2),
          checkmarkColor: const Color(0xFFFF7A20),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? const Color(0xFFFF7A20) : const Color(0xFFE2E8F0),
          ),
          labelStyle: GoogleFonts.montserrat(
            color: selected ? const Color(0xFFB45309) : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedCategoryIds.add(category.id);
              } else {
                _selectedCategoryIds.remove(category.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildExperienceFields() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _yearsController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              label: 'Años de experiencia',
              icon: Icons.timeline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _basePriceController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              label: 'Tarifa base estimada',
              icon: Icons.attach_money_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _zones.map((zone) {
        final zoneId = zone['id']!;
        final selected = _selectedZoneIds.contains(zoneId);

        return FilterChip(
          label: Text(zone['name']!),
          selected: selected,
          selectedColor: const Color(0xFFEFF6FF),
          checkmarkColor: const Color(0xFF2563EB),
          backgroundColor: Colors.white,
          side: BorderSide(
            color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
          labelStyle: GoogleFonts.montserrat(
            color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
            fontWeight: FontWeight.w700,
          ),
          onSelected: (value) {
            setState(() {
              if (value) {
                _selectedZoneIds.add(zoneId);
              } else {
                _selectedZoneIds.remove(zoneId);
              }
            });
          },
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
        label: 'Describe tu experiencia técnica, herramientas y tipo de trabajos que atiendes',
        icon: Icons.description_rounded,
      ),
    );
  }

  Widget _buildPortfolioUploader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _portfolioTitleController,
            decoration: _inputDecoration(
              label: 'Título del trabajo previo',
              icon: Icons.work_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _isUploadingPortfolio ? null : _pickAndUploadPortfolio,
              icon: _isUploadingPortfolio
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(
                _isUploadingPortfolio ? 'Subiendo...' : 'Cargar trabajo previo',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF7A20),
                side: const BorderSide(color: Color(0xFFFF7A20)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioList() {
    if (_portfolio.isEmpty) {
      return _buildEmptyBox('Aún no has cargado trabajos previos');
    }

    return Column(
      children: _portfolio.map((item) => _buildPortfolioItem(item)).toList(),
    );
  }

  Widget _buildPortfolioItem(Map<String, dynamic> item) {
    final title = item['title']?.toString() ?? 'Trabajo previo';
    final fileType = item['file_type']?.toString() ?? 'image';
    final fileUrl = item['file_url']?.toString() ?? '';
    final id = item['id']?.toString() ?? '';
    final isImage = fileType == 'image';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isImage && fileUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      fileUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_rounded, color: Color(0xFFFF7A20));
                      },
                    ),
                  )
                : const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFFF7A20)),
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
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileType == 'video' ? 'Video' : 'Imagen',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: id.isEmpty ? null : () => _deletePortfolioItem(id),
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: GoogleFonts.montserrat(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFFF7A20)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFFF7A20), width: 1.5),
      ),
      labelStyle: GoogleFonts.montserrat(
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}