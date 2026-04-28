import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:veda_app/src/core/config/app_config.dart';
import 'package:veda_app/src/core/network/api_exception.dart';
import 'package:veda_app/src/features/auth/data/models/auth_response.dart';
import 'package:veda_app/src/features/auth/data/models/auth_user.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _safePost(
      '/auth/login/',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<AuthUser> fetchMe({
    required String token,
  }) async {
    final response = await _safeGet('/auth/me/', token: token);
    if (response is Map<String, dynamic>) {
      return AuthUser.fromJson(response);
    }
    throw ApiException('Invalid user profile response.');
  }

  Future<AuthUser> updateMe({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _safePatch('/auth/me/', body: payload, token: token);
    if (response is Map<String, dynamic>) {
      return AuthUser.fromJson(response);
    }
    throw ApiException('Invalid profile update response.');
  }

  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? dateOfBirth,
    String? bloodGroup,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? bpReading,
    String? sugarLevel,
    String? heartRate,
    String? weight,
  }) async {
    final response = await _safePost(
      '/auth/register/',
      body: <String, dynamic>{
        'full_name': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'date_of_birth': dateOfBirth,
        if (bloodGroup != null && bloodGroup.isNotEmpty) 'blood_group': bloodGroup,
        if (emergencyContactName != null && emergencyContactName.isNotEmpty) 'emergency_contact_name': emergencyContactName,
        if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty) 'emergency_contact_phone': emergencyContactPhone,
        if (bpReading != null && bpReading.isNotEmpty) 'bp_reading': bpReading,
        if (sugarLevel != null && sugarLevel.isNotEmpty) 'sugar_level': sugarLevel,
        if (heartRate != null && heartRate.isNotEmpty) 'heart_rate': heartRate,
        if (weight != null && weight.isNotEmpty) 'weight': weight,
      },
    );
    return AuthResponse.fromJson(response);
  }

  Future<List<Map<String, dynamic>>> fetchMedications({
    required String token,
  }) async {
    final response = await _safeGet('/medications/', token: token);
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException('Invalid medications response.');
  }

  Future<Map<String, dynamic>> addMedication({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return await _safePost('/medications/', body: payload, token: token);
  }

  Future<List<Map<String, dynamic>>> fetchReports({
    required String token,
  }) async {
    final response = await _safeGet('/reports/', token: token);
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException('Invalid reports response.');
  }

  Future<List<Map<String, dynamic>>> fetchAppointments({
    required String token,
  }) async {
    final response = await _safeGet('/appointments/', token: token);
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException('Invalid appointments response.');
  }

  Future<List<Map<String, dynamic>>> fetchDoctors({
    required String token,
    String? area,
    String? category,
    String? city,
    String? date,
  }) async {
    final path = _withQuery('/doctors/', {
      if (area != null && area.isNotEmpty) 'area': area,
      if (category != null && category.isNotEmpty) 'category': category,
      if (city != null && city.isNotEmpty) 'city': city,
      if (date != null && date.isNotEmpty) 'date': date,
    });
    final response = await _safeGet(path, token: token);
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException('Invalid doctors response.');
  }

  Future<Map<String, dynamic>> fetchDoctorDayStatus({
    required String token,
    required String date,
  }) async {
    final path = _withQuery('/doctor/day-status/', {'date': date});
    final response = await _safeGet(path, token: token);
    if (response is Map<String, dynamic>) {
      return response;
    }
    throw ApiException('Invalid doctor day status response.');
  }

  Future<Map<String, dynamic>> updateDoctorDayStatus({
    required String token,
    required String date,
    required bool isFull,
    int? seatLimit,
  }) async {
    return _safePost(
      '/doctor/day-status/',
      token: token,
      body: {
        'date': date,
        'is_full': isFull,
        if (seatLimit != null) 'seat_limit': seatLimit,
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchDoctorAppointments({
    required String token,
    String? date,
  }) async {
    final path = _withQuery('/doctor/appointments/', {
      if (date != null && date.isNotEmpty) 'date': date,
    });
    final response = await _safeGet(path, token: token);
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }
    throw ApiException('Invalid doctor appointments response.');
  }

  Future<Map<String, dynamic>> addAppointment({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    return await _safePost('/appointments/', body: payload, token: token);
  }

  Future<void> deleteAppointment({
    required String token,
    required int id,
  }) async {
    await _safeDelete('/appointments/$id/', token: token);
  }

  Future<Map<String, dynamic>> triggerSos({
    required String token,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{'message': message};
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;
    return await _safePost(
      '/sos-logs/trigger/',
      body: payload,
      token: token,
    );
  }

  Future<Map<String, dynamic>> uploadReport({
    required String token,
    required String title,
    required String reportType,
    required String reportDate,
    required String filePath,
    String notes = '',
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/reports/');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Token $token'
      ..fields['title'] = title
      ..fields['report_type'] = reportType
      ..fields['report_date'] = reportDate
      ..fields['notes'] = notes
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw ApiException(
        _extractMessage(data) ?? 'Report upload failed.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } on http.ClientException {
      throw ApiException('Network error. Check backend URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error occurred.');
    }
  }

  Future<void> deleteReport({
    required String token,
    required int id,
  }) async {
    await _safeDelete('/reports/$id/', token: token);
  }

  Future<dynamic> _safeGet(String path, {String? token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 20));
      final data = _decodeJsonOrList(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw ApiException(
        _extractMessageMap(data) ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } on http.ClientException {
      throw ApiException('Network error. Check backend URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> _safePost(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final data = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw ApiException(
        _extractMessage(data) ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } on http.ClientException {
      throw ApiException('Network error. Check backend URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error occurred.');
    }
  }

  Future<void> _safeDelete(
    String path, {
    String? token,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: _headers(token: token),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return;
      }
      final data = _decodeJson(response.body);
      throw ApiException(
        _extractMessage(data) ?? 'Delete failed.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } on http.ClientException {
      throw ApiException('Network error. Check backend URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error occurred.');
    }
  }

  Future<Map<String, dynamic>> _safePatch(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final response = await _client
          .patch(
            Uri.parse('${AppConfig.baseUrl}$path'),
            headers: _headers(token: token),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      final data = _decodeJson(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }
      throw ApiException(
        _extractMessage(data) ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again.');
    } on SocketException {
      throw ApiException('No internet connection.');
    } on http.ClientException {
      throw ApiException('Network error. Check backend URL.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error occurred.');
    }
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  dynamic _decodeJsonOrList(String body) {
    if (body.isEmpty) return <String, dynamic>{};
    return jsonDecode(body);
  }

  String? _extractMessage(Map<String, dynamic> data) {
    final detail = data['detail'];
    if (detail is String && detail.isNotEmpty) return detail;

    for (final key in data.keys) {
      final value = data[key];
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
    }

    final nonField = data['non_field_errors'];
    if (nonField is List && nonField.isNotEmpty) return nonField.first.toString();
    return null;
  }

  String? _extractMessageMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return _extractMessage(data);
    }
    return null;
  }

  String _withQuery(String path, Map<String, String> query) {
    if (query.isEmpty) {
      return path;
    }
    final encoded = query.entries
        .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
        .join('&');
    return '$path?$encoded';
  }
}
