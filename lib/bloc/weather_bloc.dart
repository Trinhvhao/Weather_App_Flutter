import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/services/database_service.dart';
import 'package:trinh_van_hao/services/network_serice.dart';
import 'package:trinh_van_hao/services/notification_service.dart';
import 'package:trinh_van_hao/services/weather_service.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherService weatherService;
  
  final DatabaseService databaseService;

  Timer? _updateTimer;
  bool _isFirstLoad = true;
  bool _isConnected = true;
  // Đăng ký lắng nghe sự thay đổi kết nối
  StreamSubscription? _connectivitySubscription;

  // Khởi tạo WeatherBloc và thiết lập các xử lý ban đầu
  WeatherBloc(this.weatherService, this.databaseService)
      : super(WeatherInitial(isConnected: true)) {
    on<FetchWeather>(
        _fetchWeather); //  Đăng ký một event handler trong Flutter Bloc để xử lý sự kiện FetchWeather.
    on<SelectHour>(_selectHour);
    on<SwitchTab>(_switchTab);
    on<InitializeData>(_initializeData);
    on<UpdateWeatherData>(_updateWeatherData);
    on<SelectCity>(_selectCity);

    _checkConnectivity(); // Kiểm tra kết nối mạng ban đầu.
    _startUpdateTimer(); // Thiết lập bộ đếm thời gian để tự động cập nhật dữ liệu.
    _listenToConnectivity(); // Lắng nghe sự thay đổi kết nối mạng.
  }

  // --- Hàm phụ trợ (Helper Functions) ---

  // Tìm giờ gần nhất với thời gian hiện tại để hiển thị thời tiết theo giờ
  int _findNearestHour(AllTime? allTime) {
    if (allTime == null || allTime.hour.isEmpty) return 0;
    DateTime now = DateTime.now();
    int currentMinutes = now.hour * 60 + now.minute;
    int nearestIndex = 0;
    int minDiff = 24 * 60;

    for (int i = 0; i < allTime.hour.length; i++) {
      List<String> parts = allTime.hour[i].split(':');
      int hourMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      int diff = (hourMinutes - currentMinutes).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  // Tìm khung giờ tiếp theo (sau thời gian hiện tại) để hiển thị thông báo
  int _findNextHour(AllTime? allTime) {
    if (allTime == null || allTime.hour.isEmpty) return 0;
    DateTime now = DateTime.now();
    int currentMinutes = now.hour * 60 + now.minute;
    int nextIndex = 0;
    int minDiff = 24 * 60;

    for (int i = 0; i < allTime.hour.length; i++) {
      List<String> parts = allTime.hour[i].split(':');
      int hourMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      if (hourMinutes > currentMinutes) {
        int diff = hourMinutes - currentMinutes;
        if (diff < minDiff) {
          minDiff = diff;
          nextIndex = i;
        }
      }
    }
    return minDiff == 24 * 60 ? 0 : nextIndex;
  }

  // Hiển thị thông báo về thời tiết cho khung giờ tiếp theo của thành phố hiện tại
  void _showNextHourNotification(List<WeatherModel> weatherList) {
    if (weatherList[WeatherUtils.myLocationIndex].weeklyWeather.isNotEmpty) {
      final allTime =
          weatherList[WeatherUtils.myLocationIndex].weeklyWeather[0].allTime;
      if (allTime != null && allTime.hour.isNotEmpty) {
        int nextHourIndex = _findNextHour(allTime);
        String city = weatherList[WeatherUtils.myLocationIndex].name!;
        String hour = allTime.hour[nextHourIndex];
        double temp = allTime.temps[nextHourIndex];
        String desc = weatherList[WeatherUtils.myLocationIndex]
                .weeklyWeather[0]
                .description ??
            'N/A';
        print(
            'Hiển thị thông báo cho khung giờ tiếp theo: $city, $hour, $temp°C, $desc');
        NotificationService.showNotification(
          id: 2,
          title: 'Thời tiết sắp tới',
          body: 'Thời tiết tại $city vào $hour: $desc, $temp°C.',
        );
      }
    }
  }

  // Lấy dữ liệu thời tiết, ưu tiên từ API nếu có mạng, hoặc từ Firestore nếu không có mạng
  Future<List<WeatherModel>> _getWeatherData() async {
    _isConnected = await NetworkService.isConnected();
    if (!_isConnected) {
      print('Không có kết nối mạng, sử dụng dữ liệu từ Firestore');
      final weatherMap = await databaseService.fetchAllWeatherData();
      if (weatherMap.isEmpty)
        throw Exception('Không có dữ liệu trong Firestore');
      return weatherMap.values.toList();
    }
    final weatherList = await weatherService.fetchWeatherData();
    if (weatherList.isEmpty) throw Exception('Không có dữ liệu từ API');
    return weatherList;
  }

  // --- Hàm quản lý kết nối ---

  // Kiểm tra trạng thái kết nối mạng ban đầu khi WeatherBloc được khởi tạo
  Future<void> _checkConnectivity() async {
    _isConnected = await NetworkService.isConnected();
    print('Kiểm tra kết nối ban đầu: $_isConnected');
    emit(WeatherInitial(isConnected: _isConnected));
  }

  // Lắng nghe sự thay đổi kết nối mạng trong suốt vòng đời của ứng dụng
  void _listenToConnectivity() {
    _connectivitySubscription =
        NetworkService.connectivityStream.listen((result) {
      print('Connectivity stream event: $result');
      bool isConnected = !result.contains(ConnectivityResult.none);
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
            body: 'Dữ liệu cục bộ đang được sử dụng.',
          );
        }
        _updateStateWithConnection(isConnected);
      } else {
        print('No change in connectivity state');
      }
    }, onError: (error) {
      print('Connectivity stream error: $error');
    });
  }

  // Cập nhật trạng thái hiện tại với giá trị isConnected mới khi trạng thái kết nối mạng thay đổi
  void _updateStateWithConnection(bool isConnected) {
    if (state is WeatherLoaded) {
      emit((state as WeatherLoaded).copyWith(isConnected: isConnected));
    } else if (state is WeatherError) {
      emit(WeatherError((state as WeatherError).message,
          isConnected: isConnected));
    } else {
      emit(WeatherInitial(isConnected: isConnected));
    }
  }

  // --- Hàm xử lý sự kiện (Event Handlers) ---

  // Xử lý sự kiện FetchWeather, lấy dữ liệu thời tiết và cập nhật trạng thái
  Future<void> _fetchWeather(
      FetchWeather event, Emitter<WeatherState> emit) async {
    emit(WeatherLoading(isConnected: _isConnected));
    try {
      List<WeatherModel> weatherList = await _getWeatherData();
      print(
          'Dữ liệu đã được lấy thành công từ API hoặc Firestore: $weatherList');
      _showNextHourNotification(weatherList);
      emit(WeatherLoaded(weatherList: weatherList, isConnected: _isConnected));
      add(InitializeData());
    } catch (e) {
      print('Lỗi khi tải dữ liệu: $e');
      emit(WeatherError('Lỗi tải dữ liệu: $e', isConnected: _isConnected));
    }
  }

  // Xử lý sự kiện SelectHour, cập nhật chỉ số giờ được chọn trong trạng thái
  Future<void> _selectHour(SelectHour event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      emit((state as WeatherLoaded).copyWith(hourIndex: event.hourIndex));
    }
  }

  // Xử lý sự kiện SwitchTab, cập nhật tab hiện tại (dự báo hoặc không khí) trong trạng thái
  Future<void> _switchTab(SwitchTab event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      emit((state as WeatherLoaded)
          .copyWith(isForecastTab: event.isForecastTab));
    }
  }

  // Xử lý sự kiện InitializeData, khởi tạo dữ liệu sau khi lấy thành công
  Future<void> _initializeData(
      InitializeData event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      WeatherUtils.myLocationIndex = currentState.weatherList
          .indexWhere((w) => w.name == currentState.myLocation);
      int hourIndex = _findNearestHour(currentState
          .weatherList[WeatherUtils.myLocationIndex].weeklyWeather[0].allTime);
      emit(currentState.copyWith(hourIndex: hourIndex, isDataReady: true));
    }
  }

  // Xử lý sự kiện UpdateWeatherData, cập nhật dữ liệu thời tiết (tự động hoặc thủ công)
  Future<void> _updateWeatherData(
      UpdateWeatherData event, Emitter<WeatherState> emit) async {
    emit(WeatherLoading(isConnected: _isConnected));
    try {
      List<WeatherModel> weatherList;
      if (_isFirstLoad) {
        weatherList =
            (await databaseService.fetchAllWeatherData()).values.toList();
        print(
            'Dữ liệu đã được lấy từ Firestore khi khởi động ứng dụng: $weatherList');
        _isFirstLoad = false;
      } else {
        weatherList = await _getWeatherData();
        print(
            'Dữ liệu đã được lấy từ API (tự động hoặc thủ công): $weatherList');
        _showNextHourNotification(weatherList);
      }
      emit(WeatherLoaded(weatherList: weatherList, isConnected: _isConnected));
      add(InitializeData());
    } catch (e) {
      print('Lỗi khi cập nhật dữ liệu: $e');
      emit(state is WeatherLoaded
          ? state
          : WeatherError('Lỗi tải dữ liệu: $e', isConnected: _isConnected));
    }
  }

  // Xử lý sự kiện SelectCity, cập nhật thành phố được chọn và các thông tin liên quan
  Future<void> _selectCity(SelectCity event, Emitter<WeatherState> emit) async {
    if (state is WeatherLoaded) {
      final currentState = state as WeatherLoaded;
      WeatherUtils.myLocationIndex =
          currentState.weatherList.indexWhere((w) => w.name == event.cityName);
      int hourIndex = _findNearestHour(currentState
          .weatherList[WeatherUtils.myLocationIndex].weeklyWeather[0].allTime);
      _showNextHourNotification(currentState.weatherList);
      emit(currentState.copyWith(
          myLocation: event.cityName, hourIndex: hourIndex, isDataReady: true));
    }
  }

  // --- Hàm quản lý tài nguyên ---

  // Thiết lập một bộ đếm thời gian để tự động cập nhật dữ liệu thời tiết mỗi giờ
  void _startUpdateTimer() {
    _updateTimer =
        Timer.periodic(Duration(hours: 1), (_) => add(UpdateWeatherData()));
  }

  // Hủy các tài nguyên khi WeatherBloc bị hủy để tránh rò rỉ bộ nhớ
  @override
  Future<void> close() {
    _updateTimer?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
