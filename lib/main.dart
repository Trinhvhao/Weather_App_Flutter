// ignore_for_file: deprecated_member_use, unused_local_variable, avoid_print

// Import các thư viện cần thiết
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:flutter/material.dart'; // Thư viện UI của Flutter
import 'package:firebase_core/firebase_core.dart'; // Firebase Core để khởi tạo Firebase
import 'package:flutter_bloc/flutter_bloc.dart'; // Thư viện quản lý trạng thái theo Bloc
import 'package:intl/date_symbol_data_local.dart'; // Hỗ trợ dữ liệu ngày giờ theo địa phương
import 'package:trinh_van_hao/bloc/weather_bloc.dart'; // Bloc xử lý logic của ứng dụng
import 'package:trinh_van_hao/bloc/weather_event.dart'; // Các sự kiện của Bloc
import 'package:trinh_van_hao/bloc/weather_state.dart'; // Trạng thái của Bloc
import 'package:trinh_van_hao/services/database_service.dart'; // Dịch vụ cơ sở dữ liệu
import 'package:trinh_van_hao/services/notification_service.dart'; // Dịch vụ thông báo
import 'package:trinh_van_hao/services/weather_service.dart'; // Dịch vụ thời tiết
import 'package:trinh_van_hao/view/pages/navbar.dart'; // Màn hình chính có Navigation Bar
import 'package:trinh_van_hao/view/pages/forecast.dart'; // Màn hình dự báo thời tiết
import 'package:permission_handler/permission_handler.dart'; // Xử lý quyền truy cập

// Màn hình SplashScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false; // Biến kiểm tra xem đã điều hướng chưa

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xff060720), // Đặt màu nền cho màn hình splash
      body: BlocListener<WeatherBloc, WeatherState>(
        // Lắng nghe sự thay đổi của WeatherBloc
        listener: (context, state) {
          if (_hasNavigated) return; // Nếu đã điều hướng thì không làm gì cả

          if (state is WeatherLoaded || state is WeatherError) {
            _hasNavigated = true;
            Navigator.pushReplacementNamed(
                context, '/navbar'); // Chuyển đến màn hình chính
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung
            children: [
              const Icon(
                Icons.cloud,
                size: 100,
                color:
                    Colors.white, // Biểu tượng đám mây đại diện cho thời tiết
              ),
              const SizedBox(height: 20),
              const Text(
                'Weather App',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold, // Tiêu đề ứng dụng
                ),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                // Hiển thị vòng quay load
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Created by TrinhHao', // Dòng chữ ghi tác giả
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

// Hàm main - Khởi động ứng dụng
void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Đảm bảo các plugin đã được khởi tạo

  try {
    await Firebase.initializeApp(); // Khởi tạo Firebase
    print('Firebase initialized successfully');
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  // Cấu hình Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Bật tính năng lưu trữ offline
    cacheSizeBytes:
        Settings.CACHE_SIZE_UNLIMITED, // Dữ liệu có thể cache không giới hạn
  );

  await NotificationService.initialize(); // Khởi tạo dịch vụ thông báo

  // Yêu cầu quyền thông báo
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  await initializeDateFormatting(
      'vi', null); // Khởi tạo dữ liệu ngày tháng cho tiếng Việt

  final databaseService = DatabaseService();
  final weatherService = WeatherService(databaseService);

  try {
    await databaseService.syncPendingData(); // Đồng bộ dữ liệu pending
    print('Đã đồng bộ dữ liệu pending khi khởi động ứng dụng');
  } catch (e) {
    print('Lỗi khi đồng bộ dữ liệu pending: $e');
  }

  runApp(const MyApp());
}

// Cấu trúc ứng dụng chính
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = DatabaseService();
    final weatherService = WeatherService(databaseService);

    return BlocProvider(
      create: (context) => WeatherBloc(
        weatherService,
        databaseService,
      )..add(
          UpdateWeatherData()), // cascade notation cho phép gọi nhiều phương thức trên cùng một đối tượng
      child: MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(), // Màn hình Splash
          '/navbar': (context) => const NavBar(), // Màn hình chính
          '/forecast': (context) =>
              const Forecast(), // Màn hình dự báo thời tiết
        },
        debugShowCheckedModeBanner: false, // Tắt hiển thị banner debug
      ),
    );
  }
}
