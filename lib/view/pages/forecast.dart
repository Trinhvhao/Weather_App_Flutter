// ignore_for_file: deprecated_member_use, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trinh_van_hao/bloc/weather_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_state.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart';
import 'package:intl/intl.dart';
import 'package:trinh_van_hao/view/widgets/item.dart';

class Forecast extends StatefulWidget {
  const Forecast({super.key});

  @override
  State<Forecast> createState() => _ForecastState();
}

class _ForecastState extends State<Forecast> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Cuộn đến giờ được chọn khi dữ liệu sẵn sàng
      if (context.read<WeatherBloc>().state is WeatherLoaded) {
        final state = context.read<WeatherBloc>().state as WeatherLoaded;
        if (state.isDataReady) {
          await scrollToIndex(state.hourIndex);
        }
      }
    });
  }

  Future<void> scrollToIndex(int hourIndex) async {
    if (itemScrollController.isAttached) {
      await itemScrollController.scrollTo(
        index: hourIndex,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff060720),
        body: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is WeatherLoaded) {
              final weatherList = state.weatherList;
              if (weatherList.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có dữ liệu thời tiết',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              if (WeatherUtils.myLocationIndex < 0 ||
                  WeatherUtils.myLocationIndex >= weatherList.length ||
                  weatherList[WeatherUtils.myLocationIndex]
                      .weeklyWeather
                      .isEmpty) {
                return const Center(
                  child: Text(
                    'Dữ liệu thời tiết không hợp lệ',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              // Cuộn đến giờ được chọn khi dữ liệu sẵn sàng
              if (state.isDataReady) {
                scrollToIndex(state.hourIndex);
              }

              final currentDayWeather =
                  weatherList[WeatherUtils.myLocationIndex].weeklyWeather[0];
              final allTime = currentDayWeather.allTime;
              final hourCount = allTime?.hour.length ?? 0;

              // Khởi tạo dữ liệu locale tiếng Việt
              initializeDateFormatting('vi', null);
              // Lấy ngày hiện tại
              final today = DateTime.now();
              final todayFormatted =
                  DateFormat('d MMMM yyyy', 'vi').format(today);

              return SingleChildScrollView(
                child: Container(
                  height: myHeight,
                  width: myWidth,
                  padding: EdgeInsets.only(bottom: myHeight * 0.1),
                  child: Column(
                    children: [
                      SizedBox(height: myHeight * 0.03),
                      const Text(
                        'Dự báo',
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                      SizedBox(height: myHeight * 0.05),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: myWidth * 0.06),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Today',
                              style: TextStyle(
                                  fontSize: 25,
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                            Text(
                              todayFormatted,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: myHeight * 0.025),
                      Container(
                        height: myHeight * 0.15,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: myWidth * 0.03, bottom: myHeight * 0.03),
                          child: hourCount > 0
                              ? ScrollablePositionedList.builder(
                                  itemScrollController: itemScrollController,
                                  itemPositionsListener: itemPositionsListener,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  itemCount: hourCount,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: myWidth * 0.02,
                                          vertical: myHeight * 0.01),
                                      child: Container(
                                        width: myWidth * 0.35,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          color: state.hourIndex == index
                                              ? null
                                              : Colors.white.withOpacity(0.05),
                                          gradient: state.hourIndex == index
                                              ? const LinearGradient(colors: [
                                                  Color.fromARGB(
                                                      255, 21, 85, 169),
                                                  Color.fromARGB(
                                                      255, 44, 162, 246),
                                                ])
                                              : null,
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                allTime!.img[index],
                                                height: myHeight * 0.04,
                                                width: myWidth * 0.08,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                  Icons.cloud,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              SizedBox(width: myWidth * 0.04),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    allTime.hour[index],
                                                    style: const TextStyle(
                                                        fontSize: 20,
                                                        color: Colors.white),
                                                  ),
                                                  Text(
                                                    '${allTime.temps[index].toStringAsFixed(1)}°C',
                                                    style: const TextStyle(
                                                        fontSize: 25,
                                                        color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Text(
                                    'Không có dữ liệu thời tiết theo giờ',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                        ),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: myWidth * 0.06),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dự báo mới',
                              style: TextStyle(
                                  fontSize: 25,
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                            Image.asset(
                              'assets/icons/5.png',
                              height: myHeight * 0.03,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: myHeight * 0.02),
                      Container(
                        height: myHeight * 0.4,
                        child: ListView.builder(
                          itemCount: weatherList[WeatherUtils.myLocationIndex]
                              .weeklyWeather
                              .length,
                          itemBuilder: (context, index) {
                            // Bỏ qua ngày hiện tại (index 0)
                            if (index == 0) {
                              return const SizedBox.shrink();
                            }
                            final targetDate =
                                DateTime.now().add(Duration(days: index));
                            final dayFormatted =
                                int.parse(DateFormat('d').format(targetDate));
                            return Item(
                              item: weatherList[WeatherUtils.myLocationIndex]
                                  .weeklyWeather[index],
                              day: dayFormatted,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (state is WeatherError) {
              return Center(
                child: Text(
                  'Error: ${state.message}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }
            return const Center(
              child: Text(
                'Không có dữ liệu',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
