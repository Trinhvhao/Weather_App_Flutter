import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trinh_van_hao/bloc/weather_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_event.dart';
import 'package:trinh_van_hao/bloc/weather_state.dart';
import 'package:trinh_van_hao/services/database_service.dart';

class Setting extends StatefulWidget {
  const Setting({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<Setting> {
  bool? _lastConnectionState;

  Future<String> _getLastFetchTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastFetchTime') ?? 'Chưa từng tải';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: Container(
        color: const Color(0xff060720),
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<WeatherBloc, WeatherState>(
          listener: (context, state) {
            if (_lastConnectionState != state.isConnected) {
              if (!state.isConnected) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Không có kết nối mạng, sử dụng dữ liệu cục bộ'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                context.read<DatabaseService>().syncPendingData().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã đồng bộ dữ liệu thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              }
              _lastConnectionState = state.isConnected;
            }

            if (state is WeatherLoaded && state.weatherList.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Dữ liệu thời tiết đã được cập nhật thành công'),
                ),
              );
            } else if (state is WeatherError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            // Hiển thị trạng thái loading
            if (state is WeatherLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải dữ liệu thời tiết...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Giao diện chính khi không ở trạng thái loading
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Dữ liệu thời tiết',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  state.isConnected
                      ? 'Đã kết nối mạng'
                      : 'Không có kết nối mạng',
                  style: TextStyle(
                    color: state.isConnected ? Colors.green : Colors.red,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<WeatherBloc>().add(FetchWeather());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 24),
                  ),
                  child: const Text(
                    'Tải dữ liệu thời tiết mới nhất',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _getLastFetchTime(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    return Text(
                      'Thời gian tải cuối: ${snapshot.data}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
