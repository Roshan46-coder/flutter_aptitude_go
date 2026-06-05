import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'hive_database.dart';
import 'local_data.dart';

class ApiClient extends ChangeNotifier {
  late Dio dio;
  late CookieJar cookieJar;

  HiveDatabase get _db => HiveDatabase.instance;

  String _baseUrl = kIsWeb
      ? "http://localhost:8000/api/"
      : (defaultTargetPlatform == TargetPlatform.android
          ? "http://10.0.2.2:8000/api/"
          : "http://localhost:8000/api/");

  Map<String, dynamic>? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String get baseUrl => _baseUrl;

  String get wsBaseUrl {
    final http = _baseUrl.replaceFirst('/api/', '');
    return http.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
  }

  Future<String?> getSessionCookie() async {
    try {
      final uri = Uri.parse(_baseUrl);
      final cookies = await cookieJar.loadForRequest(uri);
      for (final c in cookies) {
        if (c.name == 'sessionid') return c.value;
      }
    } catch (_) {}
    return null;
  }

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    cookieJar = CookieJar();
    if (!kIsWeb) {
      dio.interceptors.add(CookieManager(cookieJar));
    } else {
      dio.options.extra['withCredentials'] = true;
    }

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }

    _loadSavedSession();
  }

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    dio.options.baseUrl = newUrl;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> _loadSavedSession() async {
    final user = _db.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  Future<void> _saveLocalSession(Map<String, dynamic> userData) async {
    _currentUser = userData;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    _currentUser = null;
    _isAuthenticated = false;
    await _db.clearCurrentUser();
    notifyListeners();
  }

  // ── AUTH APIs (Hive-local) ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    _setLoading(true);
    try {
      final result = await _db.loginUser(username, password);

      _setLoading(false);
      if (result['success'] == true) {
        await _saveLocalSession(result['user']);
        return {'success': true, 'message': result['message']};
      }
      return {'success': false, 'error': result['error'] ?? 'Login failed'};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required bool isCompany,
    String? firstName,
    String? lastName,
    String? currentStatus,
    String? interestedField,
    String? hiringFocus,
    String? organization,
  }) async {
    _setLoading(true);
    try {
      final result = await _db.registerUser(
        username: username,
        email: email,
        password: password,
        isCompany: isCompany,
        firstName: firstName,
        lastName: lastName,
        currentStatus: currentStatus,
        interestedField: interestedField,
        hiringFocus: hiringFocus,
        organization: organization,
      );

      _setLoading(false);
      if (result['success'] == true) {
        return {'success': true, 'message': result['message'], 'email': email};
      }
      return {'success': false, 'error': result['error'] ?? 'Registration failed'};
    } catch (e) {
      _setLoading(false);
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  void updateCurrentUser(Map<String, dynamic> data) {
    _currentUser ??= {};
    _currentUser!.addAll(data);
    notifyListeners();
  }

  void addCoins(int amount) {
    if (_currentUser != null) {
      final current = (_currentUser!['coins'] as num?)?.toInt() ?? 0;
      _currentUser!['coins'] = current + amount;
      notifyListeners();
    }
  }

  void updateUserStats({
    required int coins,
    required int exp,
    required int level,
    required int lives,
  }) {
    if (_currentUser == null) return;
    _currentUser!['coins'] = coins;
    _currentUser!['exp'] = exp;
    _currentUser!['level'] = level;
    _currentUser!['lives'] = lives;
    notifyListeners();
    _db.updateCurrentUser({
      'coins': coins,
      'exp': exp,
      'level': level,
      'lives': lives,
    });
  }

  Future<void> logout() async {
    _setLoading(true);
    await _clearLocalSession();
    _setLoading(false);
  }

  Future<bool> checkAuthStatus() async {
    final user = _db.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }
    if (_isAuthenticated) {
      _clearLocalSession();
    }
    return false;
  }

  Future<Map<String, dynamic>> verifyEmailLocally(String email) async {
    return await _db.verifyUser(email);
  }

  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    return await _db.resendVerification(email);
  }

  String _localPath(String path) {
    if (path.startsWith('http')) {
      try {
        return Uri.parse(path).path;
      } catch (_) {}
    }
    return path;
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _clearLocalSession();
      }
      final local = LocalDataProvider.instance.get(_localPath(path), queryParameters: queryParameters);
      if (local != null) {
        return Response(requestOptions: e.requestOptions, data: local, statusCode: 200);
      }
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.post(path, data: data, queryParameters: queryParameters);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _clearLocalSession();
      }
      final local = LocalDataProvider.instance.post(_localPath(path), data: data);
      if (local != null) {
        return Response(requestOptions: e.requestOptions, data: local, statusCode: 200);
      }
      rethrow;
    }
  }
}
