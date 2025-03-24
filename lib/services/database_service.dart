import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/network_serice.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference weatherCollection =
      FirebaseFirestore.instance.collection('weather_data');

  DatabaseService() {
    _clearOldCache();
  }

  Future<void> _clearOldCache() async {
    final cache = WeatherCache();
    await cache.clearAllWeatherData();
  }

  Future<void> saveWeatherData(String apiCityName, WeatherModel weather) async {
    try {
      final updatedWeather = WeatherModel(
        name: weather.name,
        weeklyWeather: weather.weeklyWeather,
        airQuality: weather.airQuality,
        lastUpdated: DateTime.now(),
      );

      // Kiểm tra kết nối mạng
      bool isConnected = await NetworkService.isConnected();
      if (!isConnected) {
        print('Không có kết nối mạng, lưu dữ liệu vào cache để đồng bộ sau');
        final cache = WeatherCache();
        await cache.saveWeatherData(apiCityName, updatedWeather);
        await cache.markPendingSync(apiCityName); // Đánh dấu cần đồng bộ
        return;
      }

      // Nếu có mạng, lưu vào Firestore và xóa dữ liệu pending
      final docRef = weatherCollection.doc(apiCityName);
      await docRef.set(updatedWeather.toJson(), SetOptions(merge: false));

      final cache = WeatherCache();
      await cache.saveWeatherData(apiCityName, updatedWeather);
      await cache.clearPendingSync(apiCityName); // Xóa đánh dấu pending
    } catch (e) {
      print('Lỗi khi lưu dữ liệu thời tiết cho $apiCityName: $e');
      rethrow;
    }
  }

  Future<Map<String, WeatherModel>> fetchAllWeatherData() async {
    try {
      final querySnapshot = await weatherCollection.get();
      final weatherMap = <String, WeatherModel>{};
      for (var doc in querySnapshot.docs) {
        try {
          weatherMap[doc.id] =
              WeatherModel.fromJson(doc.data() as Map<String, dynamic>);
        } catch (e) {
          print('Lỗi khi phân tích dữ liệu thời tiết cho ${doc.id}: $e');
          weatherMap[doc.id] = WeatherModel(
            name: doc.id,
            weeklyWeather: [],
            lastUpdated: DateTime.now(),
          );
        }
      }
      return weatherMap;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu thời tiết từ Firestore: $e');
      final cache = WeatherCache();
      final cachedWeatherMap = await cache.getAllWeatherData();
      if (cachedWeatherMap.isNotEmpty) {
        return cachedWeatherMap;
      }
      throw Exception('Không thể lấy dữ liệu từ Firestore hoặc cache: $e');
    }
  }

  Future<WeatherModel?> fetchWeatherDataForCity(String apiCityName) async {
    try {
      final cache = WeatherCache();
      WeatherModel? cachedWeather = await cache.getWeatherData(apiCityName);
      if (cachedWeather != null &&
          cachedWeather.lastUpdated != null &&
          DateTime.now().difference(cachedWeather.lastUpdated!).inHours < 1) {
        return cachedWeather;
      }

      final doc = await weatherCollection.doc(apiCityName).get();
      if (doc.exists) {
        final weather =
            WeatherModel.fromJson(doc.data() as Map<String, dynamic>);
        await cache.saveWeatherData(apiCityName, weather);
        return weather;
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu thời tiết cho $apiCityName: $e');
      final cache = WeatherCache();
      final cachedWeather = await cache.getWeatherData(apiCityName);
      if (cachedWeather != null) {
        return cachedWeather;
      }
      return null;
    }
  }

  // Đồng bộ dữ liệu pending khi có mạng
  Future<void> syncPendingData() async {
    final cache = WeatherCache();
    final pendingCities = await cache.getPendingSyncCities();
    if (pendingCities.isEmpty) return;

    bool isConnected = await NetworkService.isConnected();
    if (!isConnected) {
      print('Không có kết nối mạng, không thể đồng bộ dữ liệu pending');
      return;
    }

    for (var city in pendingCities) {
      final weather = await cache.getWeatherData(city);
      if (weather != null) {
        final docRef = weatherCollection.doc(city);
        await docRef.set(weather.toJson(), SetOptions(merge: false));
        await cache.clearPendingSync(city);
        print('Đã đồng bộ dữ liệu cho $city từ cache lên Firestore');
      }
    }
  }
}

class WeatherCache {
  static const String cacheKeyPrefix = 'weather_';
  static const String pendingSyncKey =
      'pending_sync'; // Thêm key để lưu danh sách pending

  Future<void> saveWeatherData(String apiCityName, WeatherModel weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          cacheKeyPrefix + apiCityName, jsonEncode(weather.toJson()));
    } catch (e) {
      print('Lỗi khi lưu dữ liệu thời tiết vào cache: $e');
    }
  }

  Future<WeatherModel?> getWeatherData(String apiCityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(cacheKeyPrefix + apiCityName);
      if (data != null) {
        final weather = WeatherModel.fromJson(jsonDecode(data));
        return weather;
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu thời tiết từ cache: $e');
      return null;
    }
  }

  Future<Map<String, WeatherModel>> getAllWeatherData() async {
    final weatherMap = <String, WeatherModel>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith(cacheKeyPrefix)) {
          final data = prefs.getString(key);
          if (data != null) {
            final apiCityName = key.replaceFirst(cacheKeyPrefix, '');
            final weather = WeatherModel.fromJson(jsonDecode(data));
            weatherMap[apiCityName] = weather;
          }
        }
      }
      return weatherMap;
    } catch (e) {
      print('Lỗi khi lấy tất cả dữ liệu thời tiết từ cache: $e');
      return weatherMap;
    }
  }

  Future<void> clearWeatherData(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cacheKeyPrefix + apiCityName);
  }

  Future<void> clearAllWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (var key in keys) {
      if (key.startsWith(cacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  // Đánh dấu thành phố cần đồng bộ
  Future<void> markPendingSync(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingCities = prefs.getStringList(pendingSyncKey) ?? [];
    if (!pendingCities.contains(apiCityName)) {
      pendingCities.add(apiCityName);
      await prefs.setStringList(pendingSyncKey, pendingCities);
    }
  }

  // Lấy danh sách thành phố cần đồng bộ
  Future<List<String>> getPendingSyncCities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(pendingSyncKey) ?? [];
  }

  // Xóa đánh dấu đồng bộ
  Future<void> clearPendingSync(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pendingCities = prefs.getStringList(pendingSyncKey) ?? [];
    pendingCities.remove(apiCityName);
    await prefs.setStringList(pendingSyncKey, pendingCities);
  }
}
