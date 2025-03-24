import 'package:equatable/equatable.dart';

class WeatherModel extends Equatable {
  final String? name;
  final List<WeeklyWeather> weeklyWeather;
  final AirQuality? airQuality;
  final DateTime? lastUpdated;

  const WeatherModel({
    this.name,
    this.weeklyWeather = const [],
    this.airQuality,
    this.lastUpdated,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      name: json['name'] as String? ?? 'Unknown',
      weeklyWeather: (json['weekly_weather'] as List<dynamic>?)
              ?.map((e) => WeeklyWeather.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      airQuality: json['air_quality'] != null
          ? AirQuality.fromJson(json['air_quality'] as Map<String, dynamic>)
          : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weekly_weather': weeklyWeather.map((e) => e.toJson()).toList(),
      'air_quality': airQuality?.toJson(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [name, weeklyWeather, airQuality, lastUpdated];
}

class WeeklyWeather extends Equatable {
  final String? description;
  final String? mainImg;
  final AllTime? allTime;
  final double? avgTemp;

  const WeeklyWeather({
    this.description,
    this.mainImg,
    this.allTime,
    this.avgTemp,
  });

  factory WeeklyWeather.fromJson(Map<String, dynamic> json) {
    return WeeklyWeather(
      description: json['description'] as String? ?? 'N/A',
      mainImg: json['main_img'] as String? ?? 'assets/img/4.png',
      allTime: json['all_time'] != null
          ? AllTime.fromJson(json['all_time'] as Map<String, dynamic>)
          : null,
      avgTemp: (json['avg_temp'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'main_img': mainImg,
      'all_time': allTime?.toJson(),
      'avg_temp': avgTemp,
    };
  }

  @override
  List<Object?> get props => [description, mainImg, allTime, avgTemp];
}

class AllTime extends Equatable {
  final List<String> hour;
  final List<String> img;
  final List<double> temps;
  final List<double> wind;
  final List<int> humidities;

  const AllTime({
    this.hour = const [],
    this.img = const [],
    this.temps = const [],
    this.wind = const [],
    this.humidities = const [],
  });

  factory AllTime.fromJson(Map<String, dynamic> json) {
    return AllTime(
      hour:
          (json['hour'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      img: (json['img'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      temps: (json['temps'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      wind: (json['wind'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      humidities: (json['humidities'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'img': img,
      'temps': temps,
      'wind': wind,
      'humidities': humidities,
    };
  }

  @override
  List<Object?> get props => [hour, img, temps, wind, humidities];
}

class AirQuality extends Equatable {
  final int? aqi;
  final Map<String, double>? components;
  final int? dt;

  const AirQuality({
    this.aqi,
    this.components,
    this.dt,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('list') && (json['list'] as List).isNotEmpty) {
      final main = json['list'][0];
      return AirQuality(
        aqi: main['main']?['aqi'] as int?,
        components: main['components'] != null
            ? (main['components'] as Map<String, dynamic>)
                .map((key, value) => MapEntry(key, (value as num).toDouble()))
            : null,
        dt: main['dt'] as int?,
      );
    }
    return AirQuality(
      aqi: json['main']?['aqi'] as int?,
      components: json['components'] != null
          ? (json['components'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, (value as num).toDouble()))
          : null,
      dt: json['dt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main': {'aqi': aqi},
      'components': components,
      'dt': dt,
    };
  }

  @override
  List<Object?> get props => [aqi, components, dt];
}
