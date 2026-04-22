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
    } else {
      await prefs.remove('userName');
      await prefs.remove('userRole');
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

    final response = await api.post(
      '/auth/register',
      data: body,
    );

    print('REGISTER STATUS: ${response.statusCode}');
    print('REGISTER DATA: ${response.data}');

    return response.data;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userName');
    await prefs.remove('userRole');
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
}