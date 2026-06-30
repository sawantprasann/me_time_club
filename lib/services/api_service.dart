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
    final requestBody = {'user': userParams};

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
        String? token;
        final authHeader =
            response.headers['Authorization'] ??
            response.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          token = authHeader.substring(7).trim();
        }
        if (token == null || token.isEmpty) {
          token = decoded['token'] as String?;
        }
        if (token == null) {
          throw ApiException('No token returned in response.');
        }
        final userJson = decoded['user'] as Map<String, dynamic>;

        // Map backend fields to UserProfile model
        return UserProfile.fromJson({...userJson, 'token': token});
      } else if (response.statusCode == 422) {
        final errors = decoded['errors'] as List<dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          throw ApiException(errors.join(', '));
        }
        throw ApiException('Registration failed: Unprocessable entity.');
      } else {
        final errorMsg =
            decoded['error'] as String? ??
            'An unexpected error occurred during registration.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
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
      'user': {'email': email.trim(), 'password': password},
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
        String? token;
        final authHeader =
            response.headers['Authorization'] ??
            response.headers['authorization'];
        if (authHeader != null && authHeader.startsWith('Bearer ')) {
          token = authHeader.substring(7).trim();
        }
        if (token == null || token.isEmpty) {
          token = decoded['token'] as String?;
        }
        if (token == null) {
          throw ApiException('No token returned in response.');
        }
        final userJson = decoded['user'] as Map<String, dynamic>;

        return UserProfile.fromJson({...userJson, 'token': token});
      } else if (response.statusCode == 401) {
        throw ApiException(
          decoded['error'] as String? ?? 'Invalid credentials.',
        );
      } else {
        final errorMsg =
            decoded['error'] as String? ??
            'An unexpected error occurred during login.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Generates the daily page content for the user.
  /// Throws ApiException if the request fails.
  static Future<Map<String, dynamic>> generateDailyPage({
    required String token,
    required String? mood,
    required String freeText,
  }) async {
    final url = 'http://139.59.23.15/api/v1/daily_pages/generate';
    final requestBody = {'mood': mood, 'free_text': freeText};

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedMap = decoded as Map<String, dynamic>;

        bool fromFallback = false;
        if (decodedMap.containsKey('from_fallback')) {
          fromFallback = decodedMap['from_fallback'] as bool? ?? false;
        } else if (decodedMap.containsKey('data') &&
            decodedMap['data'] is Map<String, dynamic>) {
          fromFallback = decodedMap['data']['from_fallback'] as bool? ?? false;
        }

        final content = DailyPageContent.fromJson(decodedMap);
        return {'content': content, 'from_fallback': fromFallback};
      } else {
        final errorMsg =
            decoded['error'] as String? ??
            'An unexpected error occurred during page generation.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Submits feedback for a generated daily page.
  static Future<void> submitFeedback({
    required String token,
    required String pageId,
    required String vote, // 'up' | 'down'
    String? feedbackText,
    String? mood,
    String? openingThought,
  }) async {
    final url = 'http://139.59.23.15/api/v1/daily_pages/$pageId/feedback';
    final requestBody = {
      'feedback': {
        'vote': vote,
        if (feedbackText != null) 'feedback_text': feedbackText,
        if (mood != null) 'mood': mood,
        if (openingThought != null)
          'opening_thought': openingThought.substring(
            0,
            openingThought.length > 100 ? 100 : openingThought.length,
          ),
      },
    };

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to submit feedback.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Creates a new task.
  static Future<Map<String, dynamic>> createTask({
    required String token,
    required String title,
    required bool completed,
  }) async {
    const url = 'http://139.59.23.15/api/v1/tasks';
    final requestBody = {
      'task': {'title': title, 'completed': completed},
    };

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to create task.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Gets details of a specific task.
  static Future<Map<String, dynamic>> getTask({
    required String token,
    required String taskId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/tasks/$taskId';

    print('[API REQUEST] GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[API RESPONSE] ${response.statusCode} GET $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg = decoded['error'] as String? ?? 'Failed to get task.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Deletes a specific task.
  static Future<void> deleteTask({
    required String token,
    required String taskId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/tasks/$taskId';

    print('[API REQUEST] DELETE $url');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      print('[API RESPONSE] ${response.statusCode} DELETE $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Failed to delete task (status code: ${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Updates a specific task.
  static Future<Map<String, dynamic>> updateTask({
    required String token,
    required String taskId,
    required bool completed,
    String? title,
  }) async {
    final url = 'http://139.59.23.15/api/v1/tasks/$taskId';
    final requestBody = {
      'task': {if (title != null) 'title': title, 'completed': completed},
    };

    print('[API REQUEST] PATCH $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} PATCH $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to update task.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Creates a new journal entry.
  static Future<Map<String, dynamic>> createJournalEntry({
    required String token,
    required String body,
  }) async {
    const url = 'http://139.59.23.15/api/v1/journal_entries';
    final requestBody = {
      'journal_entry': {'body': body},
    };

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to create journal entry.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Updates an existing journal entry.
  static Future<Map<String, dynamic>> updateJournalEntry({
    required String token,
    required String entryId,
    required String body,
  }) async {
    final url = 'http://139.59.23.15/api/v1/journal_entries/$entryId';
    final requestBody = {
      'journal_entry': {'body': body},
    };

    print('[API REQUEST] PATCH $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} PATCH $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to update journal entry.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Gets a daily page by its date key (YYYY-MM-DD).
  static Future<DailyPageContent?> getDailyPageByDate({
    required String token,
    required String dateKey,
  }) async {
    final url = 'http://139.59.23.15/api/v1/daily_pages/$dateKey';

    print('[API REQUEST] GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[API RESPONSE] ${response.statusCode} GET $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return DailyPageContent.fromJson(decoded);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to load daily page.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Gets all journal entries.
  static Future<List<dynamic>> getJournalEntries({
    required String token,
  }) async {
    const url = 'http://139.59.23.15/api/v1/journal_entries';

    print('[API REQUEST] GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[API RESPONSE] ${response.statusCode} GET $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded as List<dynamic>;
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to get journal entries.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Gets a specific journal entry.
  static Future<Map<String, dynamic>> getJournalEntry({
    required String token,
    required String entryId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/journal_entries/$entryId';

    print('[API REQUEST] GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[API RESPONSE] ${response.statusCode} GET $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded as Map<String, dynamic>;
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to get journal entry.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Deletes a specific journal entry.
  static Future<void> deleteJournalEntry({
    required String token,
    required String entryId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/journal_entries/$entryId';

    print('[API REQUEST] DELETE $url');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      print('[API RESPONSE] ${response.statusCode} DELETE $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Failed to delete journal entry (status code: ${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Gets all shopping items.
  static Future<List<dynamic>> getShoppingItems({required String token}) async {
    const url = 'http://139.59.23.15/api/v1/shopping_items';

    print('[API REQUEST] GET $url');

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('[API RESPONSE] ${response.statusCode} GET $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded as List<dynamic>;
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to get shopping items.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Creates a new shopping item.
  static Future<Map<String, dynamic>> createShoppingItem({
    required String token,
    required String name,
    required bool checked,
  }) async {
    const url = 'http://139.59.23.15/api/v1/shopping_items';
    final requestBody = {
      'shopping_item': {'name': name, 'checked': checked},
    };

    print('[API REQUEST] POST $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} POST $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to create shopping item.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Updates an existing shopping item.
  static Future<Map<String, dynamic>> updateShoppingItem({
    required String token,
    required String itemId,
    String? name,
    required bool checked,
  }) async {
    final url = 'http://139.59.23.15/api/v1/shopping_items/$itemId';
    final requestBody = {
      'shopping_item': {if (name != null) 'name': name, 'checked': checked},
    };

    print('[API REQUEST] PATCH $url');
    print('[API REQUEST BODY] ${jsonEncode(requestBody)}');

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('[API RESPONSE] ${response.statusCode} PATCH $url');
      print('[API RESPONSE BODY] ${response.body}');

      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return decoded as Map<String, dynamic>;
      } else {
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to update shopping item.';
        throw ApiException(errorMsg);
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Deletes a specific shopping item.
  static Future<void> deleteShoppingItem({
    required String token,
    required String itemId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/shopping_items/$itemId';

    print('[API REQUEST] DELETE $url');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );

      print('[API RESPONSE] ${response.statusCode} DELETE $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Failed to delete shopping item (status code: ${response.statusCode}).',
        );
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException(
        'Network error: Please check your internet connection.',
      );
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }
}
