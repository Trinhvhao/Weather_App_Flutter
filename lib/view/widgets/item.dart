// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';

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

    final today = DateTime.now();
    final currentDayIndex = today.day;
    final dayDifference = day != null ? day! - currentDayIndex : 0;
    final targetDate = today.add(Duration(days: dayDifference));
    final dayOfWeek = DateFormat('EEEE').format(targetDate);
    final formattedDate = DateFormat('d MMMM').format(targetDate);

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
              item!.mainImg ?? 'assets/img/4.png',
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
