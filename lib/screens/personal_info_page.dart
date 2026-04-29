import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  String _userRole = 'client';

  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  Future<void> _loadPersonalInfo() async {
    try {
      final name = await _authService.getUserName() ?? '';
      final email = await _authService.getUserEmail() ?? '';
      final role = await _authService.getUserRole() ?? 'client';

      final phone = await _authService.getUserPhone() ?? '';
      final address = await _authService.getUserAddress() ?? '';
      final city = await _authService.getUserCity() ?? '';
      final bio = await _authService.getUserBio() ?? '';

      if (!mounted) return;

      setState(() {
        _nameController.text = name;
        _emailController.text = email;
        _phoneController.text = phone;
        _addressController.text = address;
        _cityController.text = city;
        _bioController.text = bio;
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cargando información: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updatePersonalInfo(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Información actualizada correctamente'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error guardando información: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWorker = _userRole == 'technician';

    final mainColor =
        isWorker ? const Color(0xFFFF7A20) : const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Información Personal',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close : Icons.edit,
              color: Colors.white,
            ),
            onPressed: _isSaving
                ? null
                : () {
                    setState(() {
                      _isEditing = !_isEditing;
                    });
                  },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 32,
                    ),
                    decoration: BoxDecoration(
                      color: mainColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        const CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _nameController.text.isEmpty
                              ? 'Usuario'
                              : _nameController.text,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isWorker ? 'Perfil de trabajador' : 'Perfil de cliente',
                          style: GoogleFonts.montserrat(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Datos personales',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _buildInput(
                                  controller: _nameController,
                                  label: 'Nombre completo',
                                  icon: Icons.badge_outlined,
                                  enabled: _isEditing,
                                  mainColor: mainColor,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'El nombre es obligatorio';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildInput(
                                  controller: _emailController,
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
                                  enabled: false,
                                  mainColor: mainColor,
                                ),
                                const SizedBox(height: 16),
                                _buildInput(
                                  controller: _phoneController,
                                  label: 'Teléfono',
                                  icon: Icons.phone_outlined,
                                  enabled: _isEditing,
                                  mainColor: mainColor,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 16),
                                _buildInput(
                                  controller: _addressController,
                                  label: 'Dirección',
                                  icon: Icons.location_on_outlined,
                                  enabled: _isEditing,
                                  mainColor: mainColor,
                                ),
                                const SizedBox(height: 16),
                                _buildInput(
                                  controller: _cityController,
                                  label: 'Ciudad',
                                  icon: Icons.location_city_outlined,
                                  enabled: _isEditing,
                                  mainColor: mainColor,
                                ),
                                const SizedBox(height: 16),
                                _buildInput(
                                  controller: _bioController,
                                  label: isWorker
                                      ? 'Descripción de tus servicios'
                                      : 'Descripción personal',
                                  icon: Icons.description_outlined,
                                  enabled: _isEditing,
                                  mainColor: mainColor,
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_isEditing)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed:
                                    _isSaving ? null : _savePersonalInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mainColor,
                                  disabledBackgroundColor:
                                      mainColor.withOpacity(0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'Guardar cambios',
                                        style: GoogleFonts.montserrat(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          if (!_isEditing)
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditing = true;
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: mainColor,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  'Editar información',
                                  style: GoogleFonts.montserrat(
                                    color: mainColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required Color mainColor,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: enabled ? mainColor : Colors.grey,
        ),
        filled: true,
        fillColor: enabled ? const Color(0xFFF8FAFC) : const Color(0xFFEFF1F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: mainColor,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }
}