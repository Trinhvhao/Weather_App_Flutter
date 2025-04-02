// lib/services/location_service.dart
// ignore_for_file: deprecated_member_use

import 'package:geolocator/geolocator.dart';

class LocationService {
  // Hàm kiểm tra và yêu cầu quyền truy cập vị trí
  Future<bool> _checkAndRequestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra xem dịch vụ vị trí có được bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Dịch vụ vị trí bị tắt');
      return false;
    }

    // Kiểm tra quyền truy cập vị trí
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Quyền truy cập vị trí bị từ chối');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Quyền truy cập vị trí bị từ chối vĩnh viễn');
      return false;
    }

    return true;
  }

  // Hàm lấy vị trí hiện tại
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      bool hasPermission = await _checkAndRequestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return {
        'lat': position.latitude,
        'lon': position.longitude,
      };
    } catch (e) {
      print('Lỗi khi lấy vị trí hiện tại: $e');
      return null;
    }
  }
}
