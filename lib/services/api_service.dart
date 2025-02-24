import 'package:dio/dio.dart';
import '../bloc/auth_event.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl =
      "https://striking-officially-imp.ngrok-free.app/api/auth";

  Future<void> registerUser(RegisterUser event) async {
    try {
      FormData formData = FormData.fromMap({
        'name': event.name,
        'email': event.email,
        'password': event.password,
        'phone': event.phone,
        'address': event.address,
        'latlong': event.latlong,
        'confirm_password': event.confirmPassword,
        if (event.image != null)
          'image': await MultipartFile.fromFile(event.image!),
      });
      print(
          "RGDATA ${event.name} ${event.email} ${event.password} ${event.phone} ${event.address} ${event.latlong} ${event.confirmPassword}  ${event.image}");
      Response response = await _dio.post("$baseUrl/register", data: formData);
      print("Registration Response: ${response.data}");
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'];
          if (data['name'] == null ||
              data['email'] == null ||
              data['phone'] == null ||
              data['address'] == null ||
              data['image'] == null ||
              data['id'] == null) {
            throw Exception(
                "JSON break: Missing required fields in the response.");
          }
          print("Registration successful: ${responseData['message']}");
          print("User ID: ${data['id']}, Name: ${data['name']}");
        } else {
          throw Exception(
              responseData['message'] ?? "Unexpected error occurred.");
        }
      }
    } on DioException catch (e) {
      print("Dio Error: ${e.response?.statusCode} - ${e.response?.data}");
      throw Exception("Failed to register: ${e.response?.data}");
    }
  }

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    Response response = await _dio.post("$baseUrl/login", data: {
      'email': email,
      'password': password,
    });

    // Extract token details
    return {
      'accessToken': response.data['data']['token']['access_token'],
      'tokenType': response.data['data']['token']['token_type'],
      'expiresIn': response.data['data']['token']['expires_in'],
    };
  }

  Future<Map<String, dynamic>> fetchProfile(String token) async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get("$baseUrl/profile");

      if (response.statusCode == 200 && response.data['status'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception("Failed to fetch profile: $e");
    }
  }

  Future<void> logoutUser() async {
    await _dio.post("$baseUrl/logout");
  }
}
