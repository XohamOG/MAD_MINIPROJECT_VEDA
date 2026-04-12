import 'package:flutter/material.dart';
import 'package:veda_app/src/core/network/api_exception.dart';
import 'package:veda_app/src/core/network/api_service.dart';

class HealthController extends ChangeNotifier {
  HealthController({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  bool _isLoadingMedications = false;
  bool _isLoadingReports = false;
  bool _isSavingAppointment = false;
  bool _isUploadingReport = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _appointments = [];
  final Set<int> _takenToday = <int>{};

  bool get isLoadingMedications => _isLoadingMedications;
  bool get isLoadingReports => _isLoadingReports;
  bool get isSavingAppointment => _isSavingAppointment;
  bool get isUploadingReport => _isUploadingReport;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get medications => _medications;
  List<Map<String, dynamic>> get reports => _reports;
  List<Map<String, dynamic>> get appointments => _appointments;

  bool isMedicationTakenToday(int id) => _takenToday.contains(id);

  Future<void> loadDashboard(String token) async {
    await Future.wait([
      fetchMedications(token),
      fetchReports(token),
      fetchAppointments(token),
    ]);
  }

  Future<void> fetchMedications(String token) async {
    _isLoadingMedications = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _medications = await _apiService.fetchMedications(token: token);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingMedications = false;
      notifyListeners();
    }
  }

  Future<void> fetchReports(String token) async {
    _isLoadingReports = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _reports = await _apiService.fetchReports(token: token);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      _isLoadingReports = false;
      notifyListeners();
    }
  }

  void markTakenToday(int id) {
    if (_takenToday.contains(id)) {
      _takenToday.remove(id);
    } else {
      _takenToday.add(id);
    }
    notifyListeners();
  }

  Future<bool> addAppointment({
    required String token,
    required Map<String, dynamic> payload,
  }) async {
    _isSavingAppointment = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final appointment = await _apiService.addAppointment(token: token, payload: payload);
      _appointments = [appointment, ..._appointments];
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isSavingAppointment = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAppointment({
    required String token,
    required int id,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.deleteAppointment(token: token, id: id);
      _appointments = _appointments.where((item) => item['id'] != id).toList();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> fetchAppointments(String token) async {
    _errorMessage = null;
    notifyListeners();
    try {
      _appointments = await _apiService.fetchAppointments(token: token);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> uploadReport({
    required String token,
    required String title,
    required String reportType,
    required String reportDate,
    required String filePath,
    String notes = '',
  }) async {
    _isUploadingReport = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final report = await _apiService.uploadReport(
        token: token,
        title: title,
        reportType: reportType,
        reportDate: reportDate,
        filePath: filePath,
        notes: notes,
      );
      _reports = [report, ..._reports];
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isUploadingReport = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReport({
    required String token,
    required int id,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.deleteReport(token: token, id: id);
      _reports = _reports.where((item) => item['id'] != id).toList();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> triggerSos({
    required String token,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService.triggerSos(
        token: token,
        message: message,
        latitude: latitude,
        longitude: longitude,
      );
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }
}
