import 'package:flutter/material.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';

class AirQualityWidget extends StatelessWidget {
  final AirQuality? airQuality;
  final double height;
  final double width;

  const AirQualityWidget({
    super.key,
    required this.airQuality,
    required this.height,
    required this.width,
  });

  // Hàm xác định mức độ AQI theo thang 1-5 của OpenWeatherMap
  Map<String, dynamic> getAQILevel(int? aqi) {
    if (aqi == null) {
      return {
        'level': 'Không xác định',
        'color': Colors.grey,
        'message': 'Không có dữ liệu chất lượng không khí',
      };
    }

    switch (aqi) {
      case 1:
        return {
          'level': 'Tốt',
          'color': Colors.green,
          'message': 'Chất lượng không khí tốt, không gây nguy hiểm.',
        };
      case 2:
        return {
          'level': 'Trung bình',
          'color': Colors.yellow,
          'message':
              'Chất lượng không khí chấp nhận được, ảnh hưởng nhẹ đến người nhạy cảm.',
        };
      case 3:
        return {
          'level': 'Kém',
          'color': Colors.orange,
          'message':
              'Chất lượng không khí trung bình, có thể gây ảnh hưởng đến nhóm nhạy cảm.',
        };
      case 4:
        return {
          'level': 'Xấu',
          'color': Colors.red,
          'message':
              'Chất lượng không khí kém, ảnh hưởng đến sức khỏe của nhiều người.',
        };
      case 5:
        return {
          'level': 'Rất xấu',
          'color': Colors.purple,
          'message':
              'Chất lượng không khí rất kém, nguy hiểm cho sức khỏe của mọi người.',
        };
      default:
        return {
          'level': 'Không xác định',
          'color': Colors.grey,
          'message': 'Giá trị AQI không hợp lệ.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (airQuality == null || airQuality!.components == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Không có dữ liệu chất lượng không khí',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(),
            ElevatedButton(
              onPressed: () {
                // Có thể thêm logic tải lại dữ liệu nếu cần
              },
              child: const Text('Tải lại'),
            ),
          ],
        ),
      );
    }

    final aqiLevel = getAQILevel(airQuality!.aqi);

    return Container(
      height: height * 1.2, // Tăng chiều cao để chứa toàn bộ nội dung
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Hiển thị AQI và mức độ
          Text(
            'AQI: ${airQuality!.aqi ?? 'N/A'}',
            style: TextStyle(
              color: aqiLevel['color'],
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(), // Tăng khoảng cách
          Text(
            aqiLevel['level'],
            style: TextStyle(
              color: aqiLevel['color'],
              fontSize: 24,
            ),
          ),
          const SizedBox(), // Tăng khoảng cách
          // Sử dụng Flexible để thông điệp tự động xuống dòng
          Flexible(
            child: Text(
              aqiLevel['message'],
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 251, 255).withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible, // Cho phép xuống dòng
            ),
          ),
          const SizedBox(), // Tăng khoảng cách
          // Hiển thị các thông số khác
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'PM2.5: ${airQuality!.components?['pm2_5']?.toStringAsFixed(1) ?? 'N/A'} µg/m³',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                        height: 8), // Thêm khoảng cách giữa các thông số
                    Text(
                      'PM10: ${airQuality!.components?['pm10']?.toStringAsFixed(1) ?? 'N/A'} µg/m³',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CO: ${airQuality!.components?['co']?.toStringAsFixed(1) ?? 'N/A'} µg/m³',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'NO2: ${airQuality!.components?['no2']?.toStringAsFixed(1) ?? 'N/A'} µg/m³',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'SO2: ${airQuality!.components?['so2']?.toStringAsFixed(1) ?? 'N/A'} µg/m³',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O3: ${airQuality!.components?['o3']?.toStringAsFixed(1) ?? 'N/A'} µg/m³',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
