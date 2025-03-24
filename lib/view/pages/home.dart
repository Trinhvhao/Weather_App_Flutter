// ignore_for_file: unnecessary_null_comparison, sized_box_for_whitespace, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trinh_van_hao/bloc/weather_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_event.dart';
import 'package:trinh_van_hao/bloc/weather_state.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:trinh_van_hao/utils/static_file.dart';
import 'package:intl/intl.dart';
import 'package:trinh_van_hao/view/widgets/air_quality_widget.dart';

class Home extends StatefulWidget {
  final VoidCallback? onViewForecast;

  const Home({super.key, this.onViewForecast});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  // Cuộn đến giờ được chọn trong danh sách thời tiết theo giờ
  Future<void> scrollToIndex(int hourIndex) async {
    if (itemScrollController.isAttached) {
      await itemScrollController.scrollTo(
        index: hourIndex,
        duration: const Duration(seconds: 1),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Hiển thị dialog để chọn thành phố
  void _showCitySelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn thành phố'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: StaticFile.locationNameMap.length,
              itemBuilder: (context, index) {
                final cityName =
                    StaticFile.locationNameMap.values.elementAt(index);
                return ListTile(
                  title: Text(cityName),
                  onTap: () {
                    context.read<WeatherBloc>().add(SelectCity(cityName));
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double myHeight = MediaQuery.of(context).size.height;
    final double myWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff060720),
        body: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            // Trạng thái đang tải
            if (state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Trạng thái đã tải dữ liệu
            if (state is WeatherLoaded) {
              final List<WeatherModel> weatherList = state.weatherList;

              // Kiểm tra dữ liệu hợp lệ
              if (weatherList.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có dữ liệu thời tiết',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              if (StaticFile.myLocationIndex < 0 ||
                  StaticFile.myLocationIndex >= weatherList.length ||
                  weatherList[StaticFile.myLocationIndex]
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

              // Lấy dữ liệu cho ngày hiện tại
              final currentDayWeather =
                  weatherList[StaticFile.myLocationIndex].weeklyWeather[0];
              final allTime = currentDayWeather.allTime;
              final airQuality =
                  weatherList[StaticFile.myLocationIndex].airQuality;

              // Định dạng ngày hiện tại
              final today = DateTime.now();
              final todayFormatted = DateFormat('d MMMM, yyyy').format(today);

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: myWidth,
                        child: Column(
                          children: [
                            SizedBox(height: myHeight * 0.02),
                            // Tên thành phố và nút chọn thành phố
                            GestureDetector(
                              onTap: () => _showCitySelectionDialog(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.myLocation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: myHeight * 0.01),
                            // Ngày hiện tại
                            Text(
                              todayFormatted,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            SizedBox(height: myHeight * 0.03),
                            // Tab "Dự báo" và "Không khí"
                            Container(
                              height: myHeight * 0.05,
                              width: myWidth * 0.6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        context
                                            .read<WeatherBloc>()
                                            .add(SwitchTab(true));
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          gradient: state.isForecastTab
                                              ? const LinearGradient(colors: [
                                                  Color.fromARGB(
                                                      255, 21, 85, 169),
                                                  Color.fromARGB(
                                                      255, 44, 162, 246),
                                                ])
                                              : null,
                                          color: state.isForecastTab
                                              ? null
                                              : Colors.white.withOpacity(0.05),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Dự báo',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: () {
                                        context
                                            .read<WeatherBloc>()
                                            .add(SwitchTab(false));
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          gradient: !state.isForecastTab
                                              ? const LinearGradient(colors: [
                                                  Color.fromARGB(
                                                      255, 21, 85, 169),
                                                  Color.fromARGB(
                                                      255, 44, 162, 246),
                                                ])
                                              : null,
                                          color: !state.isForecastTab
                                              ? null
                                              : Colors.white.withOpacity(0.05),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'Không khí',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: myHeight * 0.03),
                            // Hiển thị hình ảnh thời tiết hoặc widget chất lượng không khí
                            state.isForecastTab
                                ? Image.asset(
                                    allTime != null &&
                                            allTime.img != null &&
                                            state.hourIndex >= 0 &&
                                            state.hourIndex < allTime.img.length
                                        ? allTime.img[state.hourIndex]
                                        : currentDayWeather.mainImg ??
                                            'assets/img/4.png',
                                    height: myHeight * 0.25,
                                    width: myWidth * 0.8,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                      Icons.cloud,
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  )
                                : AirQualityWidget(
                                    airQuality: airQuality,
                                    height: myHeight * 0.25,
                                    width: myWidth * 0.8,
                                  ),
                            SizedBox(height: myHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Hiển thị nhiệt độ, gió, độ ẩm
                  Container(
                    height: myHeight * 0.06,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  child: Text(
                                    'Nhiệt độ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FittedBox(
                                  child: Text(
                                    allTime != null &&
                                            allTime.temps != null &&
                                            state.hourIndex >= 0 &&
                                            state.hourIndex <
                                                allTime.temps.length
                                        ? '${allTime.temps[state.hourIndex].toStringAsFixed(1)}°C'
                                        : 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  child: Text(
                                    'Gió',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FittedBox(
                                  child: Text(
                                    allTime != null &&
                                            allTime.wind != null &&
                                            state.hourIndex >= 0 &&
                                            state.hourIndex <
                                                allTime.wind.length
                                        ? '${allTime.wind[state.hourIndex].toStringAsFixed(1)} km/h'
                                        : 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  child: Text(
                                    'Độ ẩm',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: FittedBox(
                                  child: Text(
                                    allTime != null &&
                                            allTime.humidities != null &&
                                            state.hourIndex >= 0 &&
                                            state.hourIndex <
                                                allTime.humidities.length
                                        ? '${allTime.humidities[state.hourIndex]}%'
                                        : 'N/A',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: myHeight * 0.01),
                  // Phần "Hôm nay" - Dữ liệu theo giờ
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: myWidth * 0.06),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Hôm nay',
                          style: TextStyle(color: Colors.white, fontSize: 28),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (widget.onViewForecast != null) {
                              widget.onViewForecast!();
                            }
                          },
                          child: const Text(
                            'Xem báo cáo đầy đủ',
                            style: TextStyle(color: Colors.blue, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: myHeight * 0.01),
                  Container(
                    height: myHeight * 0.15,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: myWidth * 0.03,
                        bottom: myHeight * 0.03,
                      ),
                      child: allTime != null &&
                              allTime.hour != null &&
                              allTime.hour.isNotEmpty
                          ? ScrollablePositionedList.builder(
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: allTime.hour.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    context
                                        .read<WeatherBloc>()
                                        .add(SelectHour(index));
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: myWidth * 0.02,
                                      vertical: myHeight * 0.01,
                                    ),
                                    child: Container(
                                      width: myWidth * 0.35,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
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
                                              allTime.img[index],
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
                                            SizedBox(width: myWidth * 0.02),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    allTime.hour[index],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      color: Colors.white,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${allTime.temps[index].toStringAsFixed(1)}°C',
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      color: Colors.white,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
                  SizedBox(height: myHeight * 0.02),
                ],
              );
            }

            // Trạng thái lỗi
            if (state is WeatherError) {
              return Center(
                child: Text(
                  'Lỗi: ${state.message}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            // Trạng thái mặc định
            return const Center(
              child: Text(
                'Nhấn để tải dữ liệu',
                style: TextStyle(color: Colors.white),
              ),
            );
          },
        ),
      ),
    );
  }
}
