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

  /// Revokes the JWT token on the server (logout).
  static Future<void> logout({required String token}) async {
    final url = '$baseUrl/logout';
    print('[API REQUEST] DELETE $url');
    try {
      await http.delete(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('[API ERROR] logout: $e');
      // Swallow errors — local session is cleared regardless
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

  /// Fetches all tasks for a specific date.
  /// Returns a list of task maps from the server.
  static Future<List<Map<String, dynamic>>> getTasksForDate({
    required String token,
    required String dateKey,
  }) async {
    final url =
        'http://139.59.23.15/api/v1/tasks?date_key=${Uri.encodeQueryComponent(dateKey)}';

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
        return List<Map<String, dynamic>>.from(decoded as List);
      } else {
        final decoded = jsonDecode(response.body);
        final errorMsg =
            decoded['error'] as String? ?? 'Failed to fetch tasks.';
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
  /// [dateKey] = YYYY-MM-DD — associates the task with a specific day on the server.
  static Future<Map<String, dynamic>> createTask({
    required String token,
    required String title,
    required bool completed,
    String? dateKey,
  }) async {
    const url = 'http://139.59.23.15/api/v1/tasks';
    final requestBody = {
      'task': {
        'title': title,
        'completed': completed,
        if (dateKey != null) 'date_key': dateKey,
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

      if (response.statusCode == 204) return {}; // No Content — success, empty body
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
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

  // ── Cycle days ──────────────────────────────────────────────────────────────

  /// Fetch all cycle days for a given month (YYYY-MM).
  static Future<List<Map<String, dynamic>>> fetchMonthCycleDays({
    required String token,
    required String month,
  }) async {
    final url = 'http://139.59.23.15/api/v1/cycle_days?month=$month';
    print('[API REQUEST] GET $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      print('[API RESPONSE] ${response.statusCode} GET $url');
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[API ERROR] fetchMonthCycleDays: $e');
      return [];
    }
  }

  /// Fetches all tasks for a specific month (YYYY-MM).
  static Future<List<Map<String, dynamic>>> fetchMonthTasks({
    required String token,
    required String month,
  }) async {
    final url = 'http://139.59.23.15/api/v1/tasks?month=$month';
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
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[API ERROR] fetchMonthTasks: $e');
      return [];
    }
  }

  /// Fetches all daily pages for a specific month (YYYY-MM).
  static Future<List<Map<String, dynamic>>> fetchMonthDailyPages({
    required String token,
    required String month,
  }) async {
    final url = 'http://139.59.23.15/api/v1/daily_pages?month=$month';
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
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[API ERROR] fetchMonthDailyPages: $e');
      return [];
    }
  }

  /// Bulk-create/upsert cycle days — marks 3 consecutive days in one call.
  /// [dateKeys] = list of YYYY-MM-DD strings.
  static Future<List<Map<String, dynamic>>> bulkCreateCycleDays({
    required String token,
    required List<String> dateKeys,
  }) async {
    const url = 'http://139.59.23.15/api/v1/cycle_days/bulk_create';
    print('[API REQUEST] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'date_keys': dateKeys}),
      );
      print('[API RESPONSE] ${response.statusCode} POST $url');
      if (response.statusCode == 201) {
        return (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[API ERROR] bulkCreateCycleDays: $e');
      return [];
    }
  }

  /// Delete a single cycle day by its API ID.
  static Future<void> deleteCycleDay({
    required String token,
    required String cycleDayId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/cycle_days/$cycleDayId';
    print('[API REQUEST] DELETE $url');
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );
      print('[API RESPONSE] ${response.statusCode} DELETE $url');
    } catch (e) {
      print('[API ERROR] deleteCycleDay: $e');
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

  // ── Categories ───────────────────────────────────────────────────────────────

  /// Fetches shopping categories (system + user-created).
  static Future<List<Map<String, dynamic>>> getShoppingCategories({
    required String token,
  }) async {
    const url = 'http://139.59.23.15/api/v1/categories';
    print('[API REQUEST] GET $url');
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'accept': 'application/json', 'Authorization': 'Bearer $token'},
      );
      print('[API RESPONSE] ${response.statusCode} GET $url');
      if (response.statusCode == 200) {
        return (jsonDecode(response.body) as List<dynamic>)
            .cast<Map<String, dynamic>>();
      }
      return [];
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      return [];
    } catch (e) {
      print('[API ERROR] getShoppingCategories: $e');
      return [];
    }
  }

  /// Creates a user-owned shopping category.
  static Future<Map<String, dynamic>?> createShoppingCategory({
    required String token,
    required String name,
    String? icon,
  }) async {
    const url = 'http://139.59.23.15/api/v1/categories';
    final requestBody = {
      'category': {
        'name': name,
        if (icon != null) 'icon': icon,
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
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return decoded as Map<String, dynamic>;
      }
      final errorMsg = decoded['errors'] != null
          ? (decoded['errors'] as List).join(', ')
          : decoded['error'] as String? ?? 'Failed to create category.';
      throw ApiException(errorMsg);
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException('Network error: Please check your internet connection.');
    } catch (e) {
      print('[API ERROR] createShoppingCategory: $e');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Deletes a user-owned shopping category.
  static Future<void> deleteShoppingCategory({
    required String token,
    required int categoryId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/categories/$categoryId';
    print('[API REQUEST] DELETE $url');
    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
      );
      print('[API RESPONSE] ${response.statusCode} DELETE $url');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
            'Failed to delete category (status: ${response.statusCode}).');
      }
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException('Network error: Please check your internet connection.');
    } catch (e) {
      print('[API ERROR] deleteShoppingCategory: $e');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Creates a new shopping item.
  static Future<Map<String, dynamic>> createShoppingItem({
    required String token,
    required String name,
    required bool checked,
    int? categoryId,
  }) async {
    const url = 'http://139.59.23.15/api/v1/shopping_items';
    final requestBody = {
      'shopping_item': {
        'name': name,
        'checked': checked,
        if (categoryId != null) 'category_id': categoryId,
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
    int? categoryId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/shopping_items/$itemId';
    final requestBody = {
      'shopping_item': {
        if (name != null) 'name': name,
        'checked': checked,
        if (categoryId != null) 'category_id': categoryId,
      },
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

  /// Gets all circle posts.
  static Future<List<dynamic>> getCirclePosts({required String token}) async {
    const url = 'http://139.59.23.15/api/v1/circle_posts';

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
            decoded['error'] as String? ?? 'Failed to get circle posts.';
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

  /// Creates a new circle post.
  static Future<Map<String, dynamic>> createCirclePost({
    required String token,
    required String body,
    bool isAnon = false,
  }) async {
    const url = 'http://139.59.23.15/api/v1/circle_posts';
    final requestBody = {
      'circle_post': {'body': body, 'is_anon': isAnon},
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
        String errorMsg = 'Failed to create circle post.';
        if (decoded is Map) {
          if (decoded['error'] != null) {
            errorMsg = decoded['error'].toString();
          } else if (decoded['errors'] != null) {
            if (decoded['errors'] is List) {
              errorMsg = (decoded['errors'] as List).join(', ');
            } else {
              errorMsg = decoded['errors'].toString();
            }
          }
        }
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

  /// Toggles a reaction on a circle post.
  /// Returns the updated post JSON (with new counts + my_reactions).
  static Future<Map<String, dynamic>?> reactToCirclePost({
    required String token,
    required String postId,
    required String reactionType,
  }) async {
    final url = 'http://139.59.23.15/api/v1/circle_posts/$postId/react';
    final requestBody = {'reaction_type': reactionType};

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw ApiException(
        'Failed to react to circle post (status: ${response.statusCode}).',
      );
    } on http.ClientException catch (e) {
      print('[API ERROR] ClientException: ${e.message}');
      throw ApiException('Network error: Please check your internet connection.');
    } catch (e) {
      print('[API ERROR] Exception: ${e.toString()}');
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Gets the user's profile.
  static Future<Map<String, dynamic>> getProfile({required String token}) async {
    const url = 'http://139.59.23.15/api/v1/profile';

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
        final errorMsg = decoded['error'] as String? ?? 'Failed to get profile.';
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

  /// Updates the user's profile.
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required Map<String, dynamic> profileParams,
  }) async {
    const url = 'http://139.59.23.15/api/v1/profile';
    final requestBody = {'profile': profileParams};

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
        String errorMsg = 'Failed to update profile.';
        if (decoded is Map) {
          if (decoded['error'] != null) {
            errorMsg = decoded['error'].toString();
          } else if (decoded['errors'] != null) {
            if (decoded['errors'] is List) {
              errorMsg = (decoded['errors'] as List).join(', ');
            } else {
              errorMsg = decoded['errors'].toString();
            }
          }
        }
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

  /// Gets all memories.
  static Future<List<dynamic>> getMemories({required String token}) async {
    const url = 'http://139.59.23.15/api/v1/memories';

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
        return decoded as List<dynamic>;
      } else {
        final errorMsg = decoded['error'] as String? ?? 'Failed to get memories.';
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

  /// Creates a new memory.
  static Future<Map<String, dynamic>> createMemory({
    required String token,
    required String title,
    required String description,
  }) async {
    const url = 'http://139.59.23.15/api/v1/memories';
    final requestBody = {
      'memory': {'title': title, 'description': description},
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
        final errorMsg = decoded['error'] as String? ?? 'Failed to create memory.';
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

  /// Updates a specific memory.
  static Future<Map<String, dynamic>> updateMemory({
    required String token,
    required String memoryId,
    String? title,
    String? description,
  }) async {
    final url = 'http://139.59.23.15/api/v1/memories/$memoryId';
    final requestBody = {
      'memory': {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      },
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
        final errorMsg = decoded['error'] as String? ?? 'Failed to update memory.';
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

  /// Deletes a specific memory.
  static Future<void> deleteMemory({
    required String token,
    required String memoryId,
  }) async {
    final url = 'http://139.59.23.15/api/v1/memories/$memoryId';

    print('[API REQUEST] DELETE $url');

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'accept': '*/*',
          'Authorization': 'Bearer $token',
        },
      );

      print('[API RESPONSE] ${response.statusCode} DELETE $url');
      print('[API RESPONSE BODY] ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ApiException(
          'Failed to delete memory (status code: ${response.statusCode}).',
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

  /// Saves user answers for a daily page (upserts by date_key).
  static Future<void> saveDailyPageAnswers({
    required String token,
    required String dateKey,
    String? reflectionAnswer,
    String? reflectionFollowupAnswer,
    String? nightReflectionAnswer,
  }) async {
    const url = 'http://139.59.23.15/api/v1/daily_pages';
    final body = {
      'daily_page': {
        'date_key': dateKey,
        if (reflectionAnswer != null) 'reflection_answer': reflectionAnswer,
        if (reflectionFollowupAnswer != null) 'reflection_followup_answer': reflectionFollowupAnswer,
        if (nightReflectionAnswer != null) 'night_reflection_answer': nightReflectionAnswer,
      },
    };
    print('[API REQUEST] POST $url');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      print('[API RESPONSE] ${response.statusCode} POST $url');
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('[API ERROR] saveDailyPageAnswers: ${response.body}');
      }
    } catch (e) {
      print('[API ERROR] saveDailyPageAnswers: $e');
    }
  }

  /// Updates a shopping category name/icon/position.
  static Future<Map<String, dynamic>> updateShoppingCategory({
    required String token,
    required int categoryId,
    String? name,
    String? icon,
    int? position,
  }) async {
    final url = 'http://139.59.23.15/api/v1/categories/$categoryId';
    final body = {
      'category': {
        if (name != null) 'name': name,
        if (icon != null) 'icon': icon,
        if (position != null) 'position': position,
      },
    };
    print('[API REQUEST] PATCH $url');
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      print('[API RESPONSE] ${response.statusCode} PATCH $url');
      final decoded = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return decoded as Map<String, dynamic>;
      }
      throw ApiException(decoded['error'] as String? ?? 'Failed to update category.');
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }
}
