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

    print('STATUS: ${response.statusCode}');
    print('DATA: ${response.data}');

    return response.data;
  }
}