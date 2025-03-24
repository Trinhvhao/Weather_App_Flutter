import 'package:equatable/equatable.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/utils/static_file.dart';

abstract class WeatherState extends Equatable {
  final bool isConnected; // Thêm thuộc tính isConnected
  const WeatherState({required this.isConnected});

  @override
  List<Object?> get props => [isConnected];
}

class WeatherInitial extends WeatherState {
  const WeatherInitial({bool isConnected = true})
      : super(isConnected: isConnected);
}

class WeatherLoading extends WeatherState {
  const WeatherLoading({bool isConnected = true})
      : super(isConnected: isConnected);
}

class WeatherLoaded extends WeatherState {
  final List<WeatherModel> weatherList;
  final int hourIndex;
  final bool isForecastTab;
  final bool isDataReady;
  final bool userSelectedHour;
  final String myLocation;
  final int myLocationIndex;

  const WeatherLoaded({
    required this.weatherList,
    this.hourIndex = 0,
    this.isForecastTab = true,
    this.isDataReady = false,
    this.userSelectedHour = false,
    this.myLocation = StaticFile.defaultDisplayLocation,
    this.myLocationIndex = 0,
    bool isConnected = true,
  }) : super(isConnected: isConnected);

  WeatherLoaded copyWith({
    List<WeatherModel>? weatherList,
    int? hourIndex,
    bool? isForecastTab,
    bool? isDataReady,
    bool? userSelectedHour,
    String? myLocation,
    int? myLocationIndex,
    bool? isConnected,
  }) {
    return WeatherLoaded(
      weatherList: weatherList ?? this.weatherList,
      hourIndex: hourIndex ?? this.hourIndex,
      isForecastTab: isForecastTab ?? this.isForecastTab,
      isDataReady: isDataReady ?? this.isDataReady,
      userSelectedHour: userSelectedHour ?? this.userSelectedHour,
      myLocation: myLocation ?? this.myLocation,
      myLocationIndex: myLocationIndex ?? this.myLocationIndex,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [
        weatherList,
        hourIndex,
        isForecastTab,
        isDataReady,
        userSelectedHour,
        myLocation,
        myLocationIndex,
        isConnected,
      ];
}

class WeatherError extends WeatherState {
  final String message;

  const WeatherError(this.message, {bool isConnected = true})
      : super(isConnected: isConnected);

  @override
  List<Object?> get props => [message, isConnected];
}
