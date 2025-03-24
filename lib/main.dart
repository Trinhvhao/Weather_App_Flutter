// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_event.dart';
import 'package:trinh_van_hao/bloc/weather_state.dart';
import 'package:trinh_van_hao/services/database_service.dart';
import 'package:trinh_van_hao/services/notification_service.dart'; // Thêm import này
import 'package:trinh_van_hao/services/weather_service.dart';
import 'package:trinh_van_hao/view/pages/bottomNavigationBar.dart'; // NavBar
import 'package:trinh_van_hao/view/pages/forecast.dart';
import 'package:permission_handler/permission_handler.dart'; // Thêm import này

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff060720),
      body: BlocListener<WeatherBloc, WeatherState>(
        listener: (context, state) {
          if (_hasNavigated) return;

          if (state is WeatherLoaded || state is WeatherError) {
            _hasNavigated = true;
            Navigator.pushReplacementNamed(context, '/navbar');
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              const Text(
                'Weather App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Created by TrinhHao',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Kích hoạt offline persistence cho Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Khởi tạo NotificationService
  await NotificationService.initialize();

  // Yêu cầu quyền thông báo
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Khởi tạo DatabaseService
    final databaseService = DatabaseService();
    // Khởi tạo WeatherService với DatabaseService
    final weatherService = WeatherService(databaseService);

    return BlocProvider(
      create: (context) => WeatherBloc(
        weatherService,
        databaseService,
      )..add(
          UpdateWeatherData()), // Sử dụng UpdateWeatherData thay vì FetchWeather
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/navbar': (context) => const NavBar(),
          '/forecast': (context) => const Forecast(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
