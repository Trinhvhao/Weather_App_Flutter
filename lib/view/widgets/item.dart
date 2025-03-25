// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import để hỗ trợ locale
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart'; // Import weather_utils.dart

class Item extends StatelessWidget {
  final WeeklyWeather? item;
  final int? day;

  const Item({super.key, required this.item, this.day});

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;

    if (item == null) {
      return const SizedBox.shrink();
    }

    // Khởi tạo dữ liệu locale tiếng Việt
    initializeDateFormatting('vi', null);

    final today = DateTime.now();
    final currentDayIndex = today.day;
    final dayDifference = day != null ? day! - currentDayIndex : 0;
    final targetDate = today.add(Duration(days: dayDifference));
    // Sử dụng DateFormat với locale 'vi' để định dạng thứ và ngày
    final dayOfWeek =
        DateFormat('EEEE', 'vi').format(targetDate); // Thứ bằng tiếng Việt
    final formattedDate = DateFormat('d MMMM', 'vi')
        .format(targetDate); // Ngày và tháng bằng tiếng Việt

    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: myHeight * 0.015, horizontal: myWidth * 0.07),
      child: Container(
        height: myHeight * 0.11,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayOfWeek,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.5), fontSize: 17),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${item!.avgTemp?.toStringAsFixed(0) ?? 'N/A'}',
                  style: const TextStyle(color: Colors.white, fontSize: 55),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '°C',
                      style: const TextStyle(color: Colors.white, fontSize: 25),
                    ),
                    const Text(''),
                  ],
                ),
              ],
            ),
            Image.asset(
              WeatherUtils.getWeatherIcon(
                  item!.description ?? ''), // Sử dụng getWeatherIcon
              height: myHeight * 0.05,
              width: myWidth * 0.1,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.cloud,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
