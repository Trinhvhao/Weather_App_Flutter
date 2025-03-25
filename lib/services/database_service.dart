// ignore_for_file: unused_field

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/network_serice.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _weatherCollection = FirebaseFirestore.instance.collection('weather_data');
  final WeatherCache _cache = WeatherCache();

  DatabaseService() {
    _clearOldCache();
  }

  Future<void> _clearOldCache() async {
    await _cache.clearAllWeatherData();
    print('Đã xóa dữ liệu cache cũ');
  }

  Future<void> saveWeatherData(String apiCityName, WeatherModel weather) async {
    try {
      final updatedWeather = WeatherModel(
        name: weather.name,
        weeklyWeather: weather.weeklyWeather,
        airQuality: weather.airQuality,
        lastUpdated: DateTime.now(),
      );

      bool isConnected = await NetworkService.isConnected();
      if (!isConnected) {
        print('Không có kết nối mạng, lưu vào cache để đồng bộ sau');
        await _cache.saveWeatherData(apiCityName, updatedWeather);
        await _cache.markPendingSync(apiCityName);
        return;
      }

      await _weatherCollection.doc(apiCityName).set(updatedWeather.toJson(), SetOptions(merge: false));
      await _cache.saveWeatherData(apiCityName, updatedWeather);
      await _cache.clearPendingSync(apiCityName);
      print('Đã lưu dữ liệu thời tiết cho $apiCityName vào Firestore');
    } catch (e) {
      print('Lỗi khi lưu dữ liệu thời tiết cho $apiCityName: $e');
      rethrow;
    }
  }

  Future<Map<String, WeatherModel>> fetchAllWeatherData() async {
    try {
      final querySnapshot = await _weatherCollection.get();
      final weatherMap = <String, WeatherModel>{};
      for (var doc in querySnapshot.docs) {
        weatherMap[doc.id] = WeatherModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      print('Đã lấy tất cả dữ liệu thời tiết từ Firestore');
      return weatherMap;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu từ Firestore: $e');
      final cachedWeatherMap = await _cache.getAllWeatherData();
      if (cachedWeatherMap.isNotEmpty) {
        print('Sử dụng dữ liệu từ cache');
        return cachedWeatherMap;
      }
      throw Exception('Không thể lấy dữ liệu từ Firestore hoặc cache: $e');
    }
  }

  Future<WeatherModel?> fetchWeatherDataForCity(String apiCityName) async {
    try {
      final cachedWeather = await _cache.getWeatherData(apiCityName);
      if (cachedWeather != null && DateTime.now().difference(cachedWeather.lastUpdated!).inHours < 1) {
        print('Dữ liệu cho $apiCityName lấy từ cache');
        return cachedWeather;
      }

      final doc = await _weatherCollection.doc(apiCityName).get();
      if (doc.exists) {
        final weather = WeatherModel.fromJson(doc.data() as Map<String, dynamic>);
        await _cache.saveWeatherData(apiCityName, weather);
        print('Đã lấy dữ liệu cho $apiCityName từ Firestore');
        return weather;
      }
      return null;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu cho $apiCityName từ Firestore: $e');
      final cachedWeather = await _cache.getWeatherData(apiCityName);
      if (cachedWeather != null) {
        print('Sử dụng dữ liệu từ cache cho $apiCityName');
        return cachedWeather;
      }
      return null;
    }
  }

  Future<void> syncPendingData() async {
    final pendingCities = await _cache.getPendingSyncCities();
    if (pendingCities.isEmpty) return;

    if (!await NetworkService.isConnected()) {
      print('Không có kết nối mạng, không thể đồng bộ dữ liệu pending');
      return;
    }

    for (var city in pendingCities) {
      final weather = await _cache.getWeatherData(city);
      if (weather != null) {
        await _weatherCollection.doc(city).set(weather.toJson(), SetOptions(merge: false));
        await _cache.clearPendingSync(city);
        print('Đã đồng bộ dữ liệu cho $city từ cache lên Firestore');
      }
    }
  }
}

class WeatherCache {
  static const String _cacheKeyPrefix = 'weather_';
  static const String _pendingSyncKey = 'pending_sync';

  Future<void> saveWeatherData(String apiCityName, WeatherModel weather) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyPrefix + apiCityName, jsonEncode(weather.toJson()));
      print('Đã lưu dữ liệu thời tiết vào cache cho $apiCityName');
    } catch (e) {
      print('Lỗi khi lưu dữ liệu vào cache: $e');
    }
  }

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

  Future<Map<String, WeatherModel>> getAllWeatherData() async {
    final weatherMap = <String, WeatherModel>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
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

  Future<void> clearAllWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix));
    for (var key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> markPendingSync(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCities = prefs.getStringList(_pendingSyncKey) ?? [];
    if (!pendingCities.contains(apiCityName)) {
      pendingCities.add(apiCityName);
      await prefs.setStringList(_pendingSyncKey, pendingCities);
    }
  }

  Future<List<String>> getPendingSyncCities() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_pendingSyncKey) ?? [];
  }

  Future<void> clearPendingSync(String apiCityName) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingCities = prefs.getStringList(_pendingSyncKey) ?? [];
    pendingCities.remove(apiCityName);
    await prefs.setStringList(_pendingSyncKey, pendingCities);
  }
}