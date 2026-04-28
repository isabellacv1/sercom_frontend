import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthService {
  final api = ApiClient().dio;

  Future<dynamic> login(String email, String password) async {
    final response = await api.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    print('LOGIN STATUS: ${response.statusCode}');
    print('LOGIN DATA: ${response.data}');

    final data = response.data;
    final prefs = await SharedPreferences.getInstance();

    final accessToken = data['access_token'];
    if (accessToken != null) {
      await prefs.setString('token', accessToken.toString());
    }

    final user = data['user'];
    if (user != null) {
      final fullName = user['fullName'] ?? user['full_name'] ?? user['name'];

      print('FULLNAME RECIBIDO EN LOGIN: $fullName');

      if (fullName != null && fullName.toString().trim().isNotEmpty) {
        await prefs.setString('userName', fullName.toString().trim());
        print('NOMBRE GUARDADO EN PREFS: ${fullName.toString().trim()}');
      } else {
        await prefs.remove('userName');
        print('NO SE PUDO GUARDAR userName');
      }

      final activeRole = user['activeRole'] ?? user['active_role'];
      if (activeRole != null && activeRole.toString().trim().isNotEmpty) {
        await prefs.setString('userRole', activeRole.toString().trim());
        print('ROL GUARDADO EN PREFS: ${activeRole.toString().trim()}');
      } else {
        await prefs.remove('userRole');
        print('NO SE PUDO GUARDAR userRole');
      }

      final userId = user['id'] ?? user['userId'] ?? user['sub'];
      if (userId != null && userId.toString().trim().isNotEmpty) {
        await prefs.setString('userId', userId.toString().trim());
      } else {
        await prefs.remove('userId');
      }
    } else {
      await prefs.remove('userName');
      await prefs.remove('userRole');
      await prefs.remove('userId');
      print('LOGIN SIN OBJETO user');
    }

    return data;
  }

  Future<dynamic> register({
    required String fullName,
    required String email,
    required String password,
    required List<String> roles,
    required String activeRole,
    String? cedula,
    String? phone,
    String? address,
    String? specialty,
  }) async {
    final body = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'roles': roles,
      'activeRole': activeRole,
      'cedula': cedula,
      'phone': phone,
      'address': address,
      'specialty': specialty,
    };

    print('REGISTER BODY: $body');

    final response = await api.post('/auth/register', data: body);

    print('REGISTER STATUS: ${response.statusCode}');
    print('REGISTER DATA: ${response.data}');

    return response.data;
  }

  Future<void> switchRole(String newRole) async {
    try {
      final data = {'active_role': newRole};
      print('SWITCH ROLE PAYLOAD: ${jsonEncode(data)}');
      await api.patch('/profiles/me/active-role', data: data);
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
      await api.patch('/profiles/me/roles', data: data);
      await switchRole('technician'); // Cambiar el rol activo inmediatamente
    } catch (e) {
      throw Exception('Error al activar perfil: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userRole');
    await prefs.remove('userId');
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

  String? _decodeUserIdFromToken(String? token) {
    if (token == null || token.trim().isEmpty) return null;

    final parts = token.split('.');
    if (parts.length < 2) return null;

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
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
