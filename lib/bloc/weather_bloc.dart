// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/database_service.dart';
import 'package:trinh_van_hao/services/network_serice.dart';
import 'package:trinh_van_hao/services/notification_service.dart';
import 'package:trinh_van_hao/services/weather_service.dart';
import 'package:trinh_van_hao/utils/static_file.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService weatherService;
  final DatabaseService databaseService;
  Timer? _updateTimer;
  bool _isFirstLoad = true;
  StreamSubscription? _connectivitySubscription;
  bool _isConnected = true;

  WeatherBloc(this.weatherService, this.databaseService)
      : super(WeatherInitial(isConnected: true)) {
    on<FetchWeather>(_onFetchWeather);
    on<SelectHour>(_onSelectHour);
    on<SwitchTab>(_onSwitchTab);
    on<InitializeData>(_onInitializeData);
    on<UpdateWeatherData>(_onUpdateWeatherData);
    on<SelectCity>(_onSelectCity);

    _checkInitialConnectivity();
    _startUpdateTimer();
    _listenToConnectivityChanges();
  }

  @override
  Future<void> close() {
    _updateTimer?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }

  void _startUpdateTimer() {
    _updateTimer = Timer.periodic(Duration(hours: 1), (timer) {
      add(UpdateWeatherData());
    });
  }

  Future<void> _checkInitialConnectivity() async {
    _isConnected = await NetworkService.isConnected();
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      emit(currentState.copyWith(isConnected: _isConnected));
    } else {
      emit(WeatherInitial(isConnected: _isConnected));
    }
  }

  void _listenToConnectivityChanges() {
    _connectivitySubscription = NetworkService.connectivityStream.listen(
        (List<ConnectivityResult> result) {
      print('Connectivity stream event: $result');
      final isConnected = !result.contains(ConnectivityResult.none);
      print('Computed isConnected: $isConnected');
      print('Previous _isConnected: $_isConnected');
      if (_isConnected != isConnected) {
        _isConnected = isConnected;
        print('Trạng thái kết nối đã thay đổi: $isConnected');
        if (!isConnected) {
          print('Calling NotificationService.showNotification()');
          NotificationService.showNotification(
            id: 0,
            title: 'Mất kết nối mạng',
            body: 'Ứng dụng đang sử dụng dữ liệu cục bộ.',
          );
        }
        if (state is WeatherLoaded) {
          final currentState = state as WeatherLoaded;
          emit(currentState.copyWith(isConnected: isConnected));
        } else if (state is WeatherInitial) {
          emit(WeatherInitial(isConnected: isConnected));
        } else if (state is WeatherError) {
          final errorState = state as WeatherError;
          emit(WeatherError(errorState.message, isConnected: isConnected));
        }
      } else {
        print('No change in connectivity state');
      }
    }, onError: (error) {
      print('Connectivity stream error: $error');
    });
  }

  Future<void> _onFetchWeather(
      FetchWeather event, Emitter<WeatherState> emit) async {
    emit(WeatherLoading(isConnected: _isConnected));
    try {
      bool isConnected = await NetworkService.isConnected();
      _isConnected = isConnected;
      if (!isConnected) {
        print('Không có kết nối mạng, sử dụng dữ liệu từ Firestore');
        final weatherMap = await databaseService.fetchAllWeatherData();
        final weatherList = weatherMap.values.toList();
        if (weatherList.isEmpty) {
          throw Exception('Không có dữ liệu thời tiết trong Firestore');
        }
        emit(WeatherLoaded(weatherList: weatherList, isConnected: false));
        return;
      }

      final weatherList = await weatherService.fetchWeatherData();
      if (weatherList.isEmpty) {
        throw Exception('Không có dữ liệu thời tiết từ API');
      }
      print('Dữ liệu đã được lấy thành công từ API: $weatherList');
      emit(WeatherLoaded(weatherList: weatherList, isConnected: true));
      add(InitializeData());
    } catch (e) {
      emit(WeatherError('Không thể tải dữ liệu từ API: $e',
          isConnected: _isConnected));
    }
  }

  Future<void> _onSelectHour(
      SelectHour event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      emit(currentState.copyWith(
        hourIndex: event.hourIndex,
      ));
    }
  }

  Future<void> _onSwitchTab(SwitchTab event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      emit(currentState.copyWith(isForecastTab: event.isForecastTab));
    }
  }

  Future<void> _onInitializeData(
      InitializeData event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      final weatherList = currentState.weatherList;

      int myLocationIndex = 0;
      for (var i = 0; i < weatherList.length; i++) {
        if (weatherList[i].name == currentState.myLocation) {
          myLocationIndex = i;
          break;
        }
      }
      StaticFile.myLocationIndex = myLocationIndex;

      int hourIndex = 0;
      if (weatherList[myLocationIndex].weeklyWeather.isNotEmpty &&
          weatherList[myLocationIndex].weeklyWeather[0].allTime != null) {
        final allTime = weatherList[myLocationIndex].weeklyWeather[0].allTime!;
        if (allTime.hour.isNotEmpty) {
          hourIndex = _findNearestHourIndex(allTime);
        }
      }

      emit(currentState.copyWith(
        hourIndex: hourIndex,
        isDataReady: true,
      ));
    }
  }

  Future<void> _onUpdateWeatherData(
      UpdateWeatherData event, Emitter<WeatherState> emit) async {
    emit(WeatherLoading(isConnected: _isConnected));
    try {
      if (_isFirstLoad) {
        final weatherMap = await databaseService.fetchAllWeatherData();
        final weatherList = weatherMap.values.toList();
        if (weatherList.isEmpty) {
          throw Exception('Không có dữ liệu thời tiết trong Firestore');
        }
        print(
            'Dữ liệu đã được lấy từ Firestore khi khởi động ứng dụng: $weatherList');
        emit(WeatherLoaded(
          weatherList: weatherList,
          isConnected: _isConnected,
        ));
        _isFirstLoad = false;
      } else {
        bool isConnected = await NetworkService.isConnected();
        _isConnected = isConnected;
        if (!isConnected) {
          print('Không có kết nối mạng, sử dụng dữ liệu từ Firestore');
          final weatherMap = await databaseService.fetchAllWeatherData();
          final weatherList = weatherMap.values.toList();
          if (weatherList.isEmpty) {
            throw Exception('Không có dữ liệu thời tiết trong Firestore');
          }
          emit(WeatherLoaded(weatherList: weatherList, isConnected: false));
          return;
        }

        final updatedWeatherList = await weatherService.fetchWeatherData();
        print(
            'Dữ liệu đã được lấy từ API (tự động hoặc thủ công): $updatedWeatherList');
        if (state is WeatherLoaded) {
          final currentState = state as WeatherLoaded;
          emit(currentState.copyWith(
            weatherList: updatedWeatherList,
            isConnected: true,
          ));
        } else {
          emit(WeatherLoaded(
              weatherList: updatedWeatherList, isConnected: true));
        }
      }
      add(InitializeData());
    } catch (e) {
      if (state is WeatherLoaded) {
        emit(state);
      } else {
        emit(WeatherError('Không thể tải dữ liệu: $e',
            isConnected: _isConnected));
      }
    }
  }

  Future<void> _onSelectCity(
      SelectCity event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      final weatherList = currentState.weatherList;

      int newLocationIndex = 0;
      for (var i = 0; i < weatherList.length; i++) {
        if (weatherList[i].name == event.cityName) {
          newLocationIndex = i;
          break;
        }
      }
      StaticFile.myLocationIndex = newLocationIndex;

      int hourIndex = 0;
      if (weatherList[newLocationIndex].weeklyWeather.isNotEmpty &&
          weatherList[newLocationIndex].weeklyWeather[0].allTime != null) {
        final allTime = weatherList[newLocationIndex].weeklyWeather[0].allTime!;
        if (allTime.hour.isNotEmpty) {
          hourIndex = _findNearestHourIndex(allTime);
        }
      }

      emit(currentState.copyWith(
        myLocation: event.cityName,
        hourIndex: hourIndex,
        isDataReady: true,
      ));
    }
  }

  int _findNearestHourIndex(AllTime allTime) {
    DateTime now = DateTime.now();
    int currentHour = now.hour;
    int nearestIndex = 0;
    int minDiff = 24;
    int nearestPastIndex = -1;
    int minPastDiff = 24;

    for (int i = 0; i < allTime.hour.length; i++) {
      String hourStr = allTime.hour[i];
      int hour = int.parse(hourStr.split(":")[0]);
      int diff = (hour - currentHour).abs();

      if (diff < minDiff) {
        minDiff = diff;
        nearestIndex = i;
      }

      if (hour <= currentHour) {
        int pastDiff = (hour - currentHour).abs();
        if (pastDiff < minPastDiff) {
          minPastDiff = pastDiff;
          nearestPastIndex = i;
        }
      }
    }

    return nearestPastIndex != -1 ? nearestPastIndex : nearestIndex;
  }
}
