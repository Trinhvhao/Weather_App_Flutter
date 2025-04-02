// lib/services/database_service.dart
// ignore_for_file: unused_field

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/network_serice.dart';

class DatabaseService {
  // --- Dependencies ---
  // Instance của FirebaseFirestore để tương tác với Firestore.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Tham chiếu đến collection 'weather_data' trên Firestore.
  final CollectionReference _weatherCollection =
      FirebaseFirestore.instance.collection('weather_data');
  // Instance của WeatherCache để quản lý dữ liệu cục bộ.
  final WeatherCache _cache = WeatherCache();

  // --- Constructor ---
  /// Khởi tạo DatabaseService và xóa dữ liệu cache cũ.
  DatabaseService() {
    _clearOldCache();
  }

  // --- Private Methods: Cache Management ---

  /// Xóa toàn bộ dữ liệu thời tiết trong cache khi khởi tạo.
  /// - Được gọi trong constructor để đảm bảo không sử dụng dữ liệu lỗi thời.
  Future<void> _clearOldCache() async {
    await _cache.clearAllWeatherData();
    print('Đã xóa dữ liệu cache cũ');
  }

  // --- Public Methods: Data Storage ---

  /// Lưu dữ liệu thời tiết vào Firestore và cache.
  /// - Nếu không có kết nối mạng, lưu vào cache và đánh dấu để đồng bộ sau.
  /// - Nếu có kết nối, lưu vào Firestore và cache, đồng thời xóa trạng thái "pending sync".
  Future<void> saveWeatherData(String apiCityName, WeatherModel weather) async {
    try {
      // Tạo WeatherModel mới với thời gian cập nhật hiện tại.
      final updatedWeather = WeatherModel(
        name: weather.name,
        weeklyWeather: weather.weeklyWeather,
        airQuality: weather.airQuality,
        lastUpdated: DateTime.now(),
      );

      // Kiểm tra trạng thái kết nối mạng.
      bool isConnected = await NetworkService.isConnected();
      if (!isConnected) {
        print('Không có kết nối mạng, lưu vào cache để đồng bộ sau');
        await _cache.saveWeatherData(apiCityName, updatedWeather);
        await _cache.markPendingSync(apiCityName);
        return;
      }

      // Lưu vào Firestore với tùy chọn không hợp nhất (overwrite).
      await _weatherCollection
          .doc(apiCityName)
          .set(updatedWeather.toJson(), SetOptions(merge: false));
      // Lưu vào cache để sử dụng khi không có kết nối.
      await _cache.saveWeatherData(apiCityName, updatedWeather);
      // Xóa trạng thái "pending sync" nếu có.
      await _cache.clearPendingSync(apiCityName);
      print('Đã lưu dữ liệu thời tiết cho $apiCityName vào Firestore');
    } catch (e) {
      print('Lỗi khi lưu dữ liệu thời tiết cho $apiCityName: $e');
      rethrow; // Ném lại ngoại lệ để lớp gọi hàm xử lý.
    }
  }

  // --- Public Methods: Data Retrieval ---

  /// Lấy toàn bộ dữ liệu thời tiết từ Firestore.
  /// - Nếu thất bại (ví dụ: không có kết nối), lấy từ cache.
  /// - Trả về một Map với key là tên thành phố và value là WeatherModel.
  Future<Map<String, WeatherModel>> fetchAllWeatherData() async {
    try {
      // Lấy tất cả tài liệu từ collection 'weather_data'.
      final querySnapshot = await _weatherCollection.get();
      final weatherMap = <String, WeatherModel>{};
      // Duyệt qua từng tài liệu và chuyển thành WeatherModel.
      for (var doc in querySnapshot.docs) {
        weatherMap[doc.id] =
            WeatherModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      print('Đã lấy tất cả dữ liệu thời tiết từ Firestore');
      return weatherMap;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu từ Firestore: $e');
      // Thử lấy dữ liệu từ cache nếu không lấy được từ Firestore.
      final cachedWeatherMap = await _cache.getAllWeatherData();
      if (cachedWeatherMap.isNotEmpty) {
        print('Sử dụng dữ liệu từ cache');
        return cachedWeatherMap;
      }
      // Nếu cả Firestore và cache đều không có dữ liệu, ném ngoại lệ.
      throw Exception('Không thể lấy dữ liệu từ Firestore hoặc cache: $e');
    }
  }

  /// Lấy dữ liệu thời tiết cho một thành phố cụ thể từ Firestore.
  Future<WeatherModel?> fetchWeatherDataForCity(String apiCityName) async {
    try {
      // Kiểm tra dữ liệu trong cache trước.
      final cachedWeather = await _cache.getWeatherData(apiCityName);
      if (cachedWeather != null &&
          DateTime.now().difference(cachedWeather.lastUpdated!).inHours < 1) {
        print('Dữ liệu cho $apiCityName lấy từ cache');
        return cachedWeather;
      }

      // Nếu không có dữ liệu trong cache hoặc dữ liệu đã cũ, lấy từ Firestore.
      final doc = await _weatherCollection.doc(apiCityName).get();
      if (doc.exists) {
        final weather =
            WeatherModel.fromJson(doc.data() as Map<String, dynamic>);
        // Lưu dữ liệu vào cache để sử dụng sau.
        await _cache.saveWeatherData(apiCityName, weather);
        print('Đã lấy dữ liệu cho $apiCityName từ Firestore');
        return weather;
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu cho $apiCityName từ Firestore: $e');
      // Thử lấy dữ liệu từ cache nếu không lấy được từ Firestore.
      final cachedWeather = await _cache.getWeatherData(apiCityName);
      if (cachedWeather != null) {
        print('Sử dụng dữ liệu từ cache cho $apiCityName');
        return cachedWeather;
      }
      return null;
    }
  }

  Future<void> syncPendingData() async {
    // Lấy danh sách các thành phố cần đồng bộ.
    final pendingCities = await _cache.getPendingSyncCities();
    if (pendingCities.isEmpty) return;

    // Kiểm tra trạng thái kết nối mạng.
    if (!await NetworkService.isConnected()) {
      print('Không có kết nối mạng, không thể đồng bộ dữ liệu pending');
      return;
    }

    // Duyệt qua từng thành phố và đồng bộ dữ liệu.
    for (var city in pendingCities) {
      final weather = await _cache.getWeatherData(city);
      if (weather != null) {
        await _weatherCollection
            .doc(city)
            .set(weather.toJson(), SetOptions(merge: false));
        await _cache.clearPendingSync(city);
        print('Đã đồng bộ dữ liệu cho $city từ cache lên Firestore');
      }
    }
  }
}

/// Lớp quản lý cache cục bộ cho dữ liệu thời tiết bằng SharedPreferences.
/// - Lưu trữ dữ liệu thời tiết cục bộ.
/// - Quản lý danh sách các thành phố cần đồng bộ (pending sync).
class WeatherCache {
  // --- Constants ---
  // Tiền tố cho các key trong SharedPreferences để lưu dữ liệu thời tiết.
  static const String _cacheKeyPrefix = 'weather_';
  // Key để lưu danh sách các thành phố cần đồng bộ.
  static const String _pendingSyncKey = 'pending_sync';

  // --- Methods: Cache Storage ---

  /// Lưu dữ liệu thời tiết vào SharedPreferences.
  /// - Chuyển WeatherModel thành JSON và lưu với key là "weather_<apiCityName>".
  Future<void> saveWeatherData(String apiCityName, WeatherModel weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKeyPrefix + apiCityName, jsonEncode(weather.toJson()));
      print('Đã lưu dữ liệu thời tiết vào cache cho $apiCityName');
    } catch (e) {
      print('Lỗi khi lưu dữ liệu vào cache: $e');
    }
  }

  /// Lấy dữ liệu thời tiết từ SharedPreferences cho một thành phố.
  /// - Trả về WeatherModel nếu có dữ liệu, hoặc null nếu không có.
  Future<WeatherModel?> getWeatherData(String apiCityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_cacheKeyPrefix + apiCityName);
      if (data != null) {
        return WeatherModel.fromJson(jsonDecode(data));
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu từ cache: $e');
      return null;
    }
  }

  /// Lấy toàn bộ dữ liệu thời tiết từ SharedPreferences.
  /// - Trả về một Map với key là tên thành phố và value là WeatherModel.
  Future<Map<String, WeatherModel>> getAllWeatherData() async {
    final weatherMap = <String, WeatherModel>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lấy tất cả các key bắt đầu bằng "weather_".
      final keys =
          prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
      for (var key in keys) {
        final data = prefs.getString(key);
        if (data != null) {
          final apiCityName = key.replaceFirst(_cacheKeyPrefix, '');
          weatherMap[apiCityName] = WeatherModel.fromJson(jsonDecode(data));
        }
      }
      return weatherMap;
    } catch (e) {
      print('Lỗi khi lấy tất cả dữ liệu từ cache: $e');
      return weatherMap;
    }
  }

  /// Xóa toàn bộ dữ liệu thời tiết trong SharedPreferences.
  /// - Xóa tất cả các key bắt đầu bằng "weather_".
  Future<void> clearAllWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys =
        prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }

  // --- Methods: Pending Sync Management ---

  /// Đánh dấu một thành phố cần đồng bộ dữ liệu lên Firestore.
  /// - Thêm tên thành phố vào danh sách "pending_sync" trong SharedPreferences.
  Future<void> markPendingSync(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCities = prefs.getStringList(_pendingSyncKey) ?? [];
    if (!pendingCities.contains(apiCityName)) {
      pendingCities.add(apiCityName);
      await prefs.setStringList(_pendingSyncKey, pendingCities);
    }
  }

  /// Lấy danh sách các thành phố cần đồng bộ dữ liệu lên Firestore.
  /// - Trả về danh sách từ "pending_sync" trong SharedPreferences.
  Future<List<String>> getPendingSyncCities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingSyncKey) ?? [];
  }

  /// Xóa một thành phố khỏi danh sách cần đồng bộ.
  /// - Xóa tên thành phố khỏi danh sách "pending_sync" trong SharedPreferences.
  Future<void> clearPendingSync(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCities = prefs.getStringList(_pendingSyncKey) ?? [];
    pendingCities.remove(apiCityName);
    await prefs.setStringList(_pendingSyncKey, pendingCities);
  }
}
