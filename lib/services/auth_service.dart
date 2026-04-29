import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  final api = ApiClient().dio;

  Future<dynamic> login(String email, String password) async {
    final response = await api.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN DATA: ${response.data}');

    final data = response.data;
    final prefs = await SharedPreferences.getInstance();

    final accessToken = data['access_token'] ?? data['accessToken'];

    if (accessToken != null && accessToken.toString().trim().isNotEmpty) {
      await prefs.setString('token', accessToken.toString());
    }

    final user = data['user'];
    final profile = data['profile'];

    if (user != null) {
      await _saveUserDataInPrefs(
        prefs: prefs,
        user: user,
        profile: profile,
        fallbackEmail: email,
      );
    } else if (profile != null) {
      await _saveProfileDataInPrefs(
        prefs: prefs,
        profile: profile,
        fallbackEmail: email,
      );
    } else {
      await prefs.remove('userName');
      await prefs.remove('userRole');
      await prefs.remove('userId');
      await prefs.setString('email', email);

      print('LOGIN SIN OBJETO user/profile');
    }

    return data;
  }

Future<dynamic> register({
  required String fullName,
  required String email,
  required String password,
  required String role,
  String? cedula,
  String? phone,
  String? address,
  String? city,
  String? bio,
  String? specialty,
  PlatformFile? cedulaDocument,
  PlatformFile? workerPhoto,
}) async {
  final fields = <String, dynamic>{
    'fullName': fullName,
    'email': email,
    'password': password,
    'role': role,
    'cedula': cedula,
    'phone': phone,
    'address': address,
    'city': city,
    'bio': bio,
    'specialty': specialty,
  };

  fields.removeWhere((key, value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    return false;
  });

  final formData = FormData.fromMap(fields);

  if (cedulaDocument != null && cedulaDocument.bytes != null) {
    formData.files.add(
      MapEntry(
        'cedula_document',
        MultipartFile.fromBytes(
          cedulaDocument.bytes!,
          filename: cedulaDocument.name,
        ),
      ),
    );
  }

  if (workerPhoto != null && workerPhoto.bytes != null) {
    formData.files.add(
      MapEntry(
        'worker_photo',
        MultipartFile.fromBytes(
          workerPhoto.bytes!,
          filename: workerPhoto.name,
        ),
      ),
    );
  }

  print('REGISTER FIELDS: $fields');
  print('CEDULA DOCUMENT: ${cedulaDocument?.name}');
  print('WORKER PHOTO: ${workerPhoto?.name}');

  final response = await api.post(
    '/auth/register',
    data: formData,
    options: Options(
      contentType: 'multipart/form-data',
    ),
  );

  print('REGISTER STATUS: ${response.statusCode}');
  print('REGISTER DATA: ${response.data}');

  return response.data;
}
Future<String?> getUserPhotoUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final photoUrl = prefs.getString('profilePhotoUrl');

  if (photoUrl != null && photoUrl.trim().isNotEmpty) {
    return photoUrl.trim();
  }

  final profile = await getCurrentProfile();

  if (profile == null) return null;

  final extractedPhotoUrl = _extractProfilePhotoUrl(profile);

  if (extractedPhotoUrl != null && extractedPhotoUrl.trim().isNotEmpty) {
    await prefs.setString('profilePhotoUrl', extractedPhotoUrl.trim());
    return extractedPhotoUrl.trim();
  }

  return null;
}

  Future<void> switchRole(String newRole) async {
    try {
      final data = {
        'active_role': newRole,
      };

      print('SWITCH ROLE PAYLOAD: ${jsonEncode(data)}');

      await api.patch(
        '/profiles/me/active-role',
        data: data,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', newRole);
    } catch (e) {
      print('ERROR IN SWITCH ROLE: $e');
      throw Exception('No se pudo cambiar el rol: $e');
    }
  }

  Future<void> activateWorkerProfile() async {
    try {
      final data = {
        'roles': ['client', 'worker'],
      };

      print('ACTIVATE WORKER PAYLOAD: ${jsonEncode(data)}');

      await api.patch(
        '/profiles/me/roles',
        data: data,
      );

      await switchRole('technician');
    } catch (e) {
      throw Exception('Error al activar perfil: $e');
    }
  }

  Future<void> updatePersonalInfo({
    required String fullName,
    required String phone,
    required String address,
    required String city,
    required String bio,
  }) async {
    try {
      final body = {
        'full_name': fullName,
        'fullName': fullName,
        'phone': phone,
        'address': address,
        'city': city,
        'bio': bio,
      };

      print('UPDATE PROFILE BODY: $body');

      final response = await api.patch(
        '/profiles/me',
        data: body,
      );

      print('UPDATE PROFILE STATUS: ${response.statusCode}');
      print('UPDATE PROFILE DATA: ${response.data}');

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userName', fullName);
      await prefs.setString('phone', phone);
      await prefs.setString('address', address);
      await prefs.setString('city', city);
      await prefs.setString('bio', bio);

      final data = response.data;

      if (data is Map<String, dynamic>) {
        final profile = data['profile'] ?? data['user'] ?? data;

        if (profile is Map<String, dynamic>) {
          await _saveProfileDataInPrefs(
            prefs: prefs,
            profile: profile,
          );
        }
      }
    } catch (e) {
      print('ERROR UPDATE PERSONAL INFO: $e');
      throw Exception('No se pudo actualizar la información personal: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      final response = await api.get('/profiles/me');

      print('GET PROFILE STATUS: ${response.statusCode}');
      print('GET PROFILE DATA: ${response.data}');

      final data = response.data;

      if (data is! Map<String, dynamic>) return null;

      final profile = data['profile'] ?? data['user'] ?? data;

      if (profile is! Map<String, dynamic>) return null;

      final prefs = await SharedPreferences.getInstance();

      await _saveProfileDataInPrefs(
        prefs: prefs,
        profile: profile,
      );

      return profile;
    } catch (e) {
      print('ERROR GET CURRENT PROFILE: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userRole');
    await prefs.remove('userId');
    await prefs.remove('email');
    await prefs.remove('phone');
    await prefs.remove('address');
    await prefs.remove('city');
    await prefs.remove('bio');
    await prefs.remove('cedula');
    await prefs.remove('specialty');
    await prefs.remove('profilePhotoUrl');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName');

    print('NOMBRE LEIDO DE PREFS: $name');

    return name;
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');

    print('ROL LEIDO DE PREFS: $role');

    return role;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('phone');
  }

  Future<String?> getUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('address');
  }

  Future<String?> getUserCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('city');
  }

  Future<String?> getUserBio() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('bio');
  }

  Future<String?> getUserCedula() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('cedula');
  }

  Future<String?> getUserSpecialty() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('specialty');
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('userId');

    if (savedId != null && savedId.trim().isNotEmpty) {
      return savedId;
    }

    final token = prefs.getString('token');
    final idFromToken = _decodeUserIdFromToken(token);

    if (idFromToken != null && idFromToken.trim().isNotEmpty) {
      await prefs.setString('userId', idFromToken.trim());
      return idFromToken.trim();
    }

    return null;
  }

  Future<void> _saveUserDataInPrefs({
    required SharedPreferences prefs,
    required dynamic user,
    dynamic profile,
    String? fallbackEmail,
  }) async {
    if (user is! Map) return;

    final fullName = user['fullName'] ??
        user['full_name'] ??
        user['name'] ??
        profile?['fullName'] ??
        profile?['full_name'] ??
        profile?['name'];

    print('FULLNAME RECIBIDO EN LOGIN: $fullName');

    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      await prefs.setString('userName', fullName.toString().trim());
      print('NOMBRE GUARDADO EN PREFS: ${fullName.toString().trim()}');
    } else {
      await prefs.remove('userName');
      print('NO SE PUDO GUARDAR userName');
    }

    final activeRole = user['activeRole'] ??
        user['active_role'] ??
        profile?['activeRole'] ??
        profile?['active_role'];

    if (activeRole != null && activeRole.toString().trim().isNotEmpty) {
      await prefs.setString('userRole', activeRole.toString().trim());
      print('ROL GUARDADO EN PREFS: ${activeRole.toString().trim()}');
    } else {
      await prefs.setString('userRole', 'client');
      print('ROL NO RECIBIDO, SE GUARDA client');
    }

    final userId = user['id'] ??
        user['userId'] ??
        user['user_id'] ??
        user['sub'] ??
        profile?['id'] ??
        profile?['userId'] ??
        profile?['user_id'];

    if (userId != null && userId.toString().trim().isNotEmpty) {
      await prefs.setString('userId', userId.toString().trim());
    } else {
      await prefs.remove('userId');
    }

    final email = user['email'] ?? profile?['email'] ?? fallbackEmail;

    if (email != null && email.toString().trim().isNotEmpty) {
      await prefs.setString('email', email.toString().trim());
    }

    if (profile is Map) {
      await _saveProfileDataInPrefs(
        prefs: prefs,
        profile: profile,
        fallbackEmail: email?.toString(),
      );
    } else {
      await _saveProfileDataInPrefs(
        prefs: prefs,
        profile: user,
        fallbackEmail: email?.toString(),
      );
    }
  }

  Future<void> _saveProfileDataInPrefs({
    required SharedPreferences prefs,
    required dynamic profile,
    String? fallbackEmail,
  }) async {
    if (profile is! Map) return;

    final fullName = profile['fullName'] ??
        profile['full_name'] ??
        profile['name'];

    if (fullName != null && fullName.toString().trim().isNotEmpty) {
      await prefs.setString('userName', fullName.toString().trim());
    }

    final activeRole = profile['activeRole'] ?? profile['active_role'];

    if (activeRole != null && activeRole.toString().trim().isNotEmpty) {
      await prefs.setString('userRole', activeRole.toString().trim());
    }

    final userId = profile['id'] ??
        profile['userId'] ??
        profile['user_id'] ??
        profile['sub'];

    if (userId != null && userId.toString().trim().isNotEmpty) {
      await prefs.setString('userId', userId.toString().trim());
    }

    final email = profile['email'] ?? fallbackEmail;

    if (email != null && email.toString().trim().isNotEmpty) {
      await prefs.setString('email', email.toString().trim());
    }

    final phone = profile['phone'] ?? profile['telefono'];

    if (phone != null) {
      await prefs.setString('phone', phone.toString());
    }

    final address = profile['address'] ?? profile['direccion'];

    if (address != null) {
      await prefs.setString('address', address.toString());
    }

    final city = profile['city'] ?? profile['ciudad'];

    if (city != null) {
      await prefs.setString('city', city.toString());
    }

    final bio = profile['bio'] ??
        profile['description'] ??
        profile['descripcion'];

    if (bio != null) {
      await prefs.setString('bio', bio.toString());
    }

    final cedula = profile['cedula'] ?? profile['document'];

    if (cedula != null) {
      await prefs.setString('cedula', cedula.toString());
    }

    final specialty = profile['specialty'] ?? profile['especialidad'];

    if (specialty != null) {
      await prefs.setString('specialty', specialty.toString());
    }
    final profilePhotoUrl = _extractProfilePhotoUrl(profile);

  if (profilePhotoUrl != null && profilePhotoUrl.trim().isNotEmpty) {
    await prefs.setString('profilePhotoUrl', profilePhotoUrl.trim());
  }
  }
  String? _extractProfilePhotoUrl(dynamic profile) {
    if (profile is! Map) return null;

    final value = profile['profile_photo_url'] ??
        profile['profilePhotoUrl'] ??
        profile['photo_url'] ??
        profile['photoUrl'] ??
        profile['avatar_url'] ??
        profile['avatarUrl'] ??
        profile['worker_photo_url'] ??
        profile['workerPhotoUrl'];

    if (value == null) return null;

    final url = value.toString().trim();

    if (url.isEmpty) return null;

    return url;
  }

  String? _decodeUserIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;

    final parts = token.split('.');

    if (parts.length < 2) return null;

    try {
      final payload = utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      );

      final data = jsonDecode(payload);

      if (data is! Map<String, dynamic>) return null;

      final id = data['sub'] ?? data['id'] ?? data['userId'] ?? data['user_id'];

      return id?.toString();
    } catch (_) {
      return null;
    }
  }
}