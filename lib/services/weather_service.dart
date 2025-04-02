// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/database_service.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart';

/// Dịch vụ lấy và xử lý dữ liệu thời tiết từ API OpenWeatherMap.
class WeatherService {
  // --- Constants ---
  static const String apiKey = '48bfbdeb553ac22ac63f77941b82cf66';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // --- Dependencies ---
  final DatabaseService databaseService;

  /// Constructor nhận một instance của DatabaseService để lưu dữ liệu vào Firestore.
  WeatherService(this.databaseService);

  // --- Public Methods ---

  /// Lấy dữ liệu thời tiết từ API và lưu vào Firestore.
  /// Trả về danh sách các WeatherModel cho tất cả thành phố.
  Future<List<WeatherModel>> fetchWeatherData() async {
    try {
      final weatherList = await _fetchWeatherFromApi();
      print('Đã lấy dữ liệu thời tiết: $weatherList');
      await _saveWeatherData(weatherList);
      return weatherList;
    } catch (e) {
      print('Lỗi khi lấy dữ liệu thời tiết: $e');
      rethrow;
    }
  }

  // --- Private Methods: Data Fetching ---

  /// Gọi API OpenWeatherMap và trả về dữ liệu JSON.
  Future<Map<String, dynamic>?> _fetchApiData(
      String url, String cityName) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        print('Không thể tải dữ liệu cho $cityName: ${response.body}');
        return null;
      }
      final data = jsonDecode(response.body);
      if (data['list'] == null || (data['list'] as List).isEmpty) {
        print('Danh sách dữ liệu trống cho $cityName');
        return null;
      }
      return data;
    } catch (e) {
      print('Lỗi khi gọi API cho $cityName: $e');
      return null;
    }
  }

  // Lấy dữ liệu thời tiết và chất lượng không khí từ API OpenWeatherMap.
  Future<List<WeatherModel>> _fetchWeatherFromApi() async {
    List<WeatherModel> weatherList = [];
    if (WeatherUtils.cityCoordinates.isEmpty) {
      print('Lỗi: Danh sách tọa độ thành phố trống');
      throw Exception('cityCoordinates is empty');
    }

    for (var cityEntry in WeatherUtils.cityCoordinates.entries) {
      final cityNameEn = cityEntry.key;
      final coords = cityEntry.value;
      if (!coords.containsKey('lat') || !coords.containsKey('lon')) {
        print('Thiếu tọa độ lat hoặc lon cho $cityNameEn: $coords');
        continue;
      }

      final lat = coords['lat']!;
      final lon = coords['lon']!;
      final cityName = WeatherUtils.locationNameMap[cityNameEn] ?? cityNameEn;

      final weatherData = await _fetchApiData(
        '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
        cityName,
      );
      if (weatherData == null) continue;

      final airQualityData = await _fetchApiData(
        '$baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$apiKey',
        cityName,
      );
      if (airQualityData == null) continue;

      weatherList.add(WeatherModel(
        name: cityName,
        weeklyWeather: _calculateDailyWeather(weatherData['list']),
        airQuality: _parseAirQuality(airQualityData),
        lastUpdated: DateTime.now(),
      ));
    }
    return weatherList;
  }

  // --- Private Methods: Data Processing ---

  /// Chuyển dữ liệu thời tiết theo giờ từ API thành danh sách dự báo hàng ngày.
  List<WeeklyWeather> _calculateDailyWeather(List<dynamic> weatherList) {
    // Nhóm dữ liệu theo ngày
    Map<String, List<Map<String, dynamic>>> dailyData = {};
    for (var entry in weatherList) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000);
      final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
      dailyData.putIfAbsent(dateKey, () => []).add(entry);
    }

    List<WeeklyWeather> weeklyWeather = [];
    int dayIndex = 0;

    for (var dailyEntries in dailyData.values) {
      List<double> temps = [];
      List<String> hours = [];
      List<String> imgs = [];
      List<double> winds = [];
      List<int> humidities = [];
      String description = 'N/A';
      String mainImg = 'assets/img/4.png';

      for (var hourlyData in dailyEntries) {
        final dateTime =
            DateTime.fromMillisecondsSinceEpoch(hourlyData['dt'] * 1000);
        temps.add(hourlyData['main']['temp'].toDouble());
        hours.add(DateFormat('HH:mm').format(dateTime));
        winds.add(hourlyData['wind']['speed'].toDouble() * 3.6);
        humidities.add(hourlyData['main']['humidity']);
        final weather = hourlyData['weather']?.isNotEmpty == true
            ? hourlyData['weather'][0]
            : null;
        final iconCode = weather?['icon'] ?? '01d';
        final mappedIcon = mapWeatherIconToAsset(iconCode);
        imgs.add(mappedIcon);
        if (description == 'N/A' && weather != null) {
          description = weather['description'] ?? 'N/A';
          mainImg = mappedIcon;
        }
      }

      double avgTemp =
          temps.isNotEmpty ? temps.reduce((a, b) => a + b) / temps.length : 0.0;
      weeklyWeather.add(WeeklyWeather(
        allTime: AllTime(
          hour: hours,
          temps: temps,
          img: imgs,
          wind: winds,
          humidities: humidities,
        ),
        description: description,
        mainImg: mainImg,
        avgTemp: avgTemp,
      ));

      if (++dayIndex >= 5) break;
    }
    return weeklyWeather;
  }

  /// Chuyển dữ liệu chất lượng không khí từ API thành đối tượng AirQuality.
  AirQuality _parseAirQuality(Map<String, dynamic> airQualityData) {
    final listData = airQualityData['list']?[0];
    if (listData == null) {
      throw Exception('Dữ liệu chất lượng không khí trống hoặc không hợp lệ');
    }
    final components = listData['components'] ?? {};
    return AirQuality(
      aqi: listData['main']?['aqi'] ?? 0,
      components: {
        'co': components['co']?.toDouble() ?? 0.0,
        'nh3': components['nh3']?.toDouble() ?? 0.0,
        'no': components['no']?.toDouble() ?? 0.0,
        'no2': components['no2']?.toDouble() ?? 0.0,
        'o3': components['o3']?.toDouble() ?? 0.0,
        'so2': components['so2']?.toDouble() ?? 0.0,
        'pm2_5': components['pm2_5']?.toDouble() ?? 0.0,
        'pm10': components['pm10']?.toDouble() ?? 0.0,
      },
      dt: listData['dt'] as int?,
    );
  }

  // --- Private Methods: Data Storage ---

  /// Lưu dữ liệu thời tiết vào Firestore và lưu thời gian lấy dữ liệu vào SharedPreferences.
  Future<void> _saveWeatherData(List<WeatherModel> weatherList) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastFetchTime', DateTime.now().toIso8601String());
    for (var weather in weatherList) {
      String apiCityName = WeatherUtils.apiLocations.firstWhere(
        (city) => WeatherUtils.locationNameMap[city] == weather.name,
        orElse: () => '',
      );
      if (apiCityName.isNotEmpty) {
        await databaseService.saveWeatherData(apiCityName, weather);
      }
    }
  }

  /// Ánh xạ mã biểu tượng thời tiết từ API thành đường dẫn hình ảnh trong assets.
  String mapWeatherIconToAsset(String iconCode) {
    const iconMap = {
      '01d': 'assets/img/13.png', // Trời nắng ban ngày
      '01n': 'assets/img/14.png', // Ban đêm không mây
      '02d': 'assets/img/1.png', // Trời nắng có mây (ban ngày)
      '02n': 'assets/img/10.png', // Trời tốt có mây (ban đêm)
      '03d': 'assets/img/4.png', // Mây
      '03n': 'assets/img/10.png', // Trời tốt có mây (ban đêm)
      '04d': 'assets/img/4.png', // Mây
      '04n': 'assets/img/10.png', // Trời tốt có mây (ban đêm)
      '09d': 'assets/img/5.png', // Mưa
      '09n': 'assets/img/11.png', // Trời tối có mây và mưa
      '10d': 'assets/img/2.png', // Ban ngày có mưa
      '10n': 'assets/img/11.png', // Trời tối có mây và mưa
      '11d': 'assets/img/7.png', // Mưa kèm sét
      '11n': 'assets/img/7.png', // Mưa kèm sét
      '13d': 'assets/img/3.png', // Ban ngày có tuyết
      '13n': 'assets/img/12.png', // Trời tối có tuyết
      '50d': 'assets/img/4.png', // Mây
      '50n': 'assets/img/10.png', // Trời tốt có mây (ban đêm)
    };
    return iconMap[iconCode] ?? 'assets/img/4.png'; // Mặc định là mây
  }
}
