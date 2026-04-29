import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  final String role;

  const RegisterPage({
    super.key,
    required this.role,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final cedulaController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final specialtyController = TextEditingController();

  final authService = AuthService();

  PlatformFile? cedulaDocumentFile;
  PlatformFile? workerPhotoFile;

  bool obscurePassword = true;
  bool isLoading = false;
  bool acceptedTerms = false;

  bool get isWorker => widget.role == 'worker';
  bool get isClient => widget.role == 'client';

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    cedulaController.dispose();
    phoneController.dispose();
    addressController.dispose();
    specialtyController.dispose();
    super.dispose();
  }

Future<void> pickCedulaDocument() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    setState(() {
      cedulaDocumentFile = result.files.first;
    });
  }
}

Future<void> pickWorkerPhoto() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    setState(() {
      workerPhotoFile = result.files.first;
    });
  }
}

  Future<void> onRegister() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final cedula = cedulaController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final specialty = specialtyController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa nombre, correo, teléfono y contraseña'),
        ),
      );
      return;
    }

    if (isWorker) {
      if (cedula.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa la cédula'),
          ),
        );
        return;
      }
    }

    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
final data = await authService.register(
  fullName: fullName,
  email: email,
  password: password,
  role: widget.role,
  cedula: isWorker ? cedula : null,
  phone: phone,
  address: isWorker ? address : null,
  specialty: isWorker ? specialty : null,
  cedulaDocument: isWorker ? cedulaDocumentFile : null,
  workerPhoto: isWorker ? workerPhotoFile : null,
);

      if (!mounted) return;

      final message = data['message']?.toString() ?? 'Registro exitoso';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Error al registrarse';

      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        final backendMessage = data['message'];

        if (backendMessage is String) {
          message = backendMessage;
        } else if (backendMessage is List && backendMessage.isNotEmpty) {
          message = backendMessage.first.toString();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F6FA);
    const primaryColor = Color(0xFF3366E8);
    const workerColor = Color(0xFFFF8A00);
    const textDark = Color(0xFF101828);
    const textSoft = Color(0xFF6B7A99);
    const borderColor = Color(0xFFD9DEE8);

    final accentColor = isWorker ? workerColor : primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.maybePop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: accentColor,
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sercom',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 34),

              Text(
                isWorker ? 'Crea tu cuenta de trabajador' : 'Crea tu cuenta',
                style: const TextStyle(
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),

              const SizedBox(height: 22),

              Text(
                isWorker
                    ? 'Completa tus datos para comenzar a recibir misiones y generar ingresos.'
                    : 'Completa tus datos para publicar misiones y encontrar al especialista ideal.',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: textSoft,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 34),

              const Text(
                'Nombre completo',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              _CustomInput(
                controller: fullNameController,
                hintText: 'Ejemplo',
                prefixIcon: Icons.person_rounded,
                accentColor: accentColor,
              ),

              const SizedBox(height: 28),

              const Text(
                'Correo electrónico',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              _CustomInput(
                controller: emailController,
                hintText: 'ejemplo@gmail.com',
                prefixIcon: Icons.mail_rounded,
                keyboardType: TextInputType.emailAddress,
                accentColor: accentColor,
              ),

              const SizedBox(height: 28),

              const Text(
                'Contraseña',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              _CustomInput(
                controller: passwordController,
                hintText: '••••••••',
                prefixIcon: Icons.lock_rounded,
                obscureText: obscurePassword,
                accentColor: accentColor,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: textSoft,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Teléfono',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 12),
              _CustomInput(
                controller: phoneController,
                hintText: 'Ingresa tu teléfono',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                accentColor: accentColor,
              ),

              if (isWorker) ...[
                const SizedBox(height: 28),

                const Text(
                  'Cédula',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _CustomInput(
                  controller: cedulaController,
                  hintText: 'Ingresa tu cédula',
                  prefixIcon: Icons.badge_rounded,
                  keyboardType: TextInputType.number,
                  accentColor: accentColor,
                ),

                const SizedBox(height: 28),

                const Text(
                  'Documento de cédula',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
_FileUploadBox(
  title: workerPhotoFile == null
      ? 'Subir foto'
      : workerPhotoFile!.name,
  icon: Icons.add_a_photo_rounded,
  accentColor: accentColor,
  onTap: pickWorkerPhoto,
),

                const SizedBox(height: 28),

                const Text(
                  'Foto del trabajador',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _FileUploadBox(
                  title: workerPhotoFile == null
                      ? 'Subir foto'
                      : workerPhotoFile!.name,
                  icon: Icons.add_a_photo_rounded,
                  accentColor: accentColor,
                  onTap: pickWorkerPhoto,
                ),

                const SizedBox(height: 28),

                const Text(
                  'Dirección',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _CustomInput(
                  controller: addressController,
                  hintText: 'Ingresa tu dirección',
                  prefixIcon: Icons.location_on_rounded,
                  accentColor: accentColor,
                ),

                const SizedBox(height: 28),

                const Text(
                  'Especialidad',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 12),
                _CustomInput(
                  controller: specialtyController,
                  hintText: 'Ej. Electricista, Plomero...',
                  prefixIcon: Icons.build_rounded,
                  accentColor: accentColor,
                ),
              ],

              const SizedBox(height: 22),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.scale(
                    scale: 1.05,
                    child: Checkbox(
                      value: acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          acceptedTerms = value ?? false;
                        });
                      },
                      shape: const CircleBorder(),
                      side: const BorderSide(color: borderColor),
                      activeColor: accentColor,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSoft,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            const TextSpan(text: 'Acepto los '),
                            TextSpan(
                              text: 'términos y condiciones',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' y la '),
                            TextSpan(
                              text: 'política de privacidad',
                              style: TextStyle(
                                color: accentColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 74,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: accentColor.withValues(alpha: 0.7),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    shadowColor: accentColor.withValues(alpha: 0.35),
                  ).copyWith(
                    elevation: const WidgetStatePropertyAll(10),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Registrarme',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 42),

              Center(
                child: Column(
                  children: [
                    const Text(
                      '¿Ya tienes una cuenta?',
                      style: TextStyle(
                        color: textSoft,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileUploadBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _FileUploadBox({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFD9DEE8);
    const textDark = Color(0xFF101828);
    const textSoft = Color(0xFF6B7A99);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: accentColor,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  color: textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.attach_file_rounded,
              color: textSoft,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Color accentColor;

  const _CustomInput({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.accentColor,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFD9DEE8);
    const textDark = Color(0xFF101828);
    const iconColor = Color(0xFF7C8AA5);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: textDark,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(prefixIcon, color: iconColor),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide(
              color: accentColor,
              width: 1.2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 22,
          ),
        ),
      ),
    );
  }
}