// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl = 'http://139.59.23.15/api/v1/auth';

  /// Performs user registration.
  /// Throws ApiException if the request fails.
  static Future<UserProfile> register({
    required Map<String, dynamic> userParams,
  }) async {
    final url = '$baseUrl/register';
    final requestBody = {
      'user': userParams,
    };

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = decoded['token'] as String;
        final userJson = decoded['user'] as Map<String, dynamic>;
        
        // Map backend fields to UserProfile model
        return UserProfile.fromJson({
          ...userJson,
          'token': token,
        });
      } else if (response.statusCode == 422) {
        final errors = decoded['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          throw ApiException(errors.join(', '));
        }
        throw ApiException('Registration failed: Unprocessable entity.');
      } else {
        final errorMsg = decoded['error'] as String? ?? 'An unexpected error occurred during registration.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException('Network error: Please check your internet connection.');
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Performs user login.
  /// Throws ApiException if the request fails.
  static Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final url = '$baseUrl/login';
    final requestBody = {
      'user': {
        'email': email.trim(),
        'password': password,
      }
    };

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = decoded['token'] as String;
        final userJson = decoded['user'] as Map<String, dynamic>;
        
        return UserProfile.fromJson({
          ...userJson,
          'token': token,
        });
      } else if (response.statusCode == 401) {
        throw ApiException(decoded['error'] as String? ?? 'Invalid credentials.');
      } else {
        final errorMsg = decoded['error'] as String? ?? 'An unexpected error occurred during login.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException('Network error: Please check your internet connection.');
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }
}
