import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/database_service.dart';
import 'package:trinh_van_hao/utils/static_file.dart';

class WeatherService {
  static const String apiKey = '48bfbdeb553ac22ac63f77941b82cf66';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  final DatabaseService databaseService;

  WeatherService(this.databaseService);
  String mapWeatherIconToAsset(String iconCode) {
    switch (iconCode) {
      // Clear sky
      case '01d':
        return 'assets/img/13.png'; // Trời nắng ban ngày không mây
      case '01n':
        return 'assets/img/14.png'; // Ban đêm không mây

      // Few clouds
      case '02d':
        return 'assets/img/1.png'; // Trời nắng có mây (ban ngày)
      case '02n':
        return 'assets/img/10.png'; // Trời tốt có mây (ban đêm)

      // Scattered clouds
      case '03d':
        return 'assets/img/4.png'; // Mây
      case '03n':
        return 'assets/img/10.png'; // Trời tốt có mây (ban đêm)

      // Broken clouds
      case '04d':
        return 'assets/img/4.png'; // Mây
      case '04n':
        return 'assets/img/10.png'; // Trời tốt có mây (ban đêm)

      // Shower rain
      case '09d':
        return 'assets/img/5.png'; // Mưa
      case '09n':
        return 'assets/img/11.png'; // Trời tối có mây và mưa

      // Rain
      case '10d':
        return 'assets/img/2.png'; // Ban ngày có mưa
      case '10n':
        return 'assets/img/11.png'; // Trời tối có mây và mưa

      // Thunderstorm
      case '11d':
        return 'assets/img/7.png'; // Mưa kèm sét
      case '11n':
        return 'assets/img/7.png'; // Mưa kèm sét

      // Snow
      case '13d':
        return 'assets/img/3.png'; // Ban ngày có tuyết
      case '13n':
        return 'assets/img/12.png'; // Trời tối có tuyết

      // Mist
      case '50d':
        return 'assets/img/4.png'; // Mây
      case '50n':
        return 'assets/img/10.png'; // Trời tốt có mây (ban đêm)

      // Mặc định
      default:
        return 'assets/img/4.png'; // Mây
    }
  }

  Future<List<WeatherModel>> fetchWeatherData() async {
    List<WeatherModel> weatherList = [];
    try {
      // Fetch dữ liệu từ API
      weatherList = await _fetchWeatherFromApi();

      // Lưu dữ liệu vào Firestore
      for (var weather in weatherList) {
        String apiCityName = StaticFile.apiLocations.firstWhere(
          (city) => StaticFile.locationNameMap[city] == weather.name,
          orElse: () => '',
        );
        if (apiCityName.isNotEmpty) {
          await databaseService.saveWeatherData(apiCityName, weather);
        }
      }

      // Lưu thời gian fetch cuối cùng vào shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastFetchTime', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error in fetchWeatherData: $e');
      rethrow;
    }
    return weatherList;
  }

  Future<List<WeatherModel>> _fetchWeatherFromApi() async {
    List<WeatherModel> weatherList = [];
    try {
      if (StaticFile.cityCoordinates.isEmpty) {
        print('Error: cityCoordinates is empty');
        throw Exception('cityCoordinates is empty');
      }

      for (var cityEntry in StaticFile.cityCoordinates.entries) {
        final String cityNameEn = cityEntry.key;
        final Map<String, double> coords = cityEntry.value;

        if (!coords.containsKey('lat') || !coords.containsKey('lon')) {
          print('Missing lat or lon for $cityNameEn: $coords');
          continue;
        }

        final double lat = coords['lat']!;
        final double lon = coords['lon']!;
        final String cityName =
            StaticFile.locationNameMap[cityNameEn] ?? cityNameEn;

        // Lấy dữ liệu thời tiết 5 ngày
        final weatherResponse = await http.get(Uri.parse(
            '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric'));
        if (weatherResponse.statusCode != 200) {
          print(
              'Failed to load weather data for $cityName: ${weatherResponse.body}');
          continue;
        }

        final weatherData = jsonDecode(weatherResponse.body);
        if (weatherData['list'] == null ||
            (weatherData['list'] as List).isEmpty) {
          print('Weather data list is empty for $cityName');
          continue;
        }

        List<WeeklyWeather> weeklyWeather =
            _calculateDailyWeather(weatherData['list']);

        // Lấy dữ liệu chất lượng không khí
        final airQualityResponse = await http.get(Uri.parse(
            '$baseUrl/air_pollution?lat=$lat&lon=$lon&appid=$apiKey'));
        if (airQualityResponse.statusCode != 200) {
          print(
              'Failed to load air quality data for $cityName: ${airQualityResponse.body}');
          continue; // Bỏ qua thành phố nếu không lấy được dữ liệu chất lượng không khí
        }

        final airQualityData = jsonDecode(airQualityResponse.body);
        final airQuality = _parseAirQuality(airQualityData);

        weatherList.add(WeatherModel(
          name: cityName,
          weeklyWeather: weeklyWeather,
          airQuality: airQuality,
          lastUpdated: DateTime.now(),
        ));
      }
    } catch (e) {
      print('Error in _fetchWeatherFromApi: $e');
      rethrow;
    }
    return weatherList;
  }

  List<WeeklyWeather> _calculateDailyWeather(List<dynamic> weatherList) {
    Map<String, List<Map<String, dynamic>>> dailyData = {};

    for (var entry in weatherList) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(entry['dt'] * 1000);
      final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = [];
      }
      dailyData[dateKey]!.add(entry);
    }

    List<WeeklyWeather> weeklyWeather = [];
    int dayIndex = 0;

    for (var entry in dailyData.entries) {
      final dailyEntries = entry.value;
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

        if (hourlyData['weather'] != null && hourlyData['weather'].isNotEmpty) {
          String iconCode = hourlyData['weather'][0]['icon'] ?? '01d';
          String mappedIcon = mapWeatherIconToAsset(iconCode);
          imgs.add(mappedIcon);
          if (description == 'N/A') {
            description = hourlyData['weather'][0]['description'] ?? 'N/A';
            mainImg = mappedIcon;
          }
        } else {
          imgs.add('assets/img/4.png');
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

      dayIndex++;
      if (dayIndex >= 5) break;
    }

    return weeklyWeather;
  }

  AirQuality _parseAirQuality(Map<String, dynamic> airQualityData) {
    if (airQualityData['list'] == null ||
        (airQualityData['list'] as List).isEmpty) {
      throw Exception('Air quality data is empty or invalid');
    }

    final listData = airQualityData['list'][0];
    final components = listData['components'] ?? {};
    return AirQuality(
      aqi: listData['main']?['aqi'] ?? 0,
      components: {
        'co': (components['co'] ?? 0).toDouble(),
        'nh3': (components['nh3'] ?? 0).toDouble(),
        'no': (components['no'] ?? 0).toDouble(),
        'no2': (components['no2'] ?? 0).toDouble(),
        'o3': (components['o3'] ?? 0).toDouble(),
        'so2': (components['so2'] ?? 0).toDouble(),
        'pm2_5': (components['pm2_5'] ?? 0).toDouble(),
        'pm10': (components['pm10'] ?? 0).toDouble(),
      },
      dt: listData['dt'] as int?,
    );
  }
}
