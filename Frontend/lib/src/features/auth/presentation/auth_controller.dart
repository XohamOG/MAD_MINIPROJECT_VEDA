import 'package:flutter/material.dart';
import 'package:veda_app/src/core/network/api_service.dart';
import 'package:veda_app/src/core/network/api_exception.dart';
import 'package:veda_app/src/features/auth/data/models/auth_user.dart';
import 'package:veda_app/src/features/auth/data/token_storage.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required ApiService apiService,
    required TokenStorage tokenStorage,
  })  : _apiService = apiService,
        _tokenStorage = tokenStorage;

  final ApiService _apiService;
  final TokenStorage _tokenStorage;

  bool _isLoading = false;
  bool _isCheckingSession = true;
  String? _errorMessage;
  String? _token;
  AuthUser? _user;

  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  AuthUser? get user => _user;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<void> restoreSession() async {
    _isCheckingSession = true;
    notifyListeners();
    final savedToken = await _tokenStorage.getToken();
    _token = savedToken;
    _isCheckingSession = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.login(email: email, password: password);
      _token = result.token;
      _user = result.user;
      await _tokenStorage.saveToken(result.token);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      _token = result.token;
      _user = result.user;
      await _tokenStorage.saveToken(result.token);
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _errorMessage = null;
    await _tokenStorage.clearToken();
    notifyListeners();
  }
}
