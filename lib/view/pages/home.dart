// ignore_for_file: unnecessary_null_comparison, sized_box_for_whitespace, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:trinh_van_hao/bloc/weather_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_event.dart';
import 'package:trinh_van_hao/bloc/weather_state.dart';
import 'package:trinh_van_hao/model/weatherModel.dart';
import 'package:intl/intl.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart';
import 'package:trinh_van_hao/view/widgets/air_quality_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

// Hằng số
class AppConstants {
  static const Color backgroundColor = Color(0xff060720);
  static const Color gradientStart = Color.fromARGB(255, 21, 85, 169);
  static const Color gradientEnd = Color.fromARGB(255, 44, 162, 246);
  static const double defaultPadding = 0.02;
  static const double defaultFontSizeLarge = 40.0;
  static const double defaultFontSizeMedium = 20.0;
  static const double defaultFontSizeSmall = 18.0;
}

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

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi', null);
  }

  Future<void> scrollToIndex(int hourIndex) async {
    await itemScrollController.scrollTo(
      index: hourIndex,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOutCubic,
    );
  }

  void _showCitySelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn thành phố',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: WeatherUtils.locationNameMap.length,
              itemBuilder: (context, index) {
                final cityName =
                    WeatherUtils.locationNameMap.values.elementAt(index);
                return ListTile(
                  title: Text(cityName,
                      style:
                          const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
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
              child: const Text('Hủy',
                  style: TextStyle(color: Color.fromARGB(255, 0, 81, 255))),
            ),
          ],
        );
      },
    );
  }

  String getSafeValue(List<dynamic>? list, int index, String unit,
      [String defaultValue = 'N/A']) {
    if (list != null && index >= 0 && index < list.length) {
      return '${list[index].toStringAsFixed(1)}$unit';
    }
    return defaultValue;
  }

  Widget buildTab(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isSelected
                ? const LinearGradient(colors: [
                    AppConstants.gradientStart,
                    AppConstants.gradientEnd
                  ])
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.05),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppConstants.defaultFontSizeMedium),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildWeatherInfo(String label, String value) {
    return Expanded(
      flex: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FittedBox(
              child: Text(
                label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: AppConstants.defaultFontSizeSmall),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: FittedBox(
              child: Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppConstants.defaultFontSizeSmall),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double myHeight = MediaQuery.of(context).size.height;
    final double myWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: BlocBuilder<WeatherBloc, WeatherState>(
          builder: (context, state) {
            if (state is WeatherLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is WeatherLoaded) {
              final List<WeatherModel> weatherList = state.weatherList;

              if (weatherList.isEmpty ||
                  WeatherUtils.myLocationIndex < 0 ||
                  WeatherUtils.myLocationIndex >= weatherList.length ||
                  weatherList[WeatherUtils.myLocationIndex]
                      .weeklyWeather
                      .isEmpty) {
                return const Center(
                    child: Text('Dữ liệu thời tiết không hợp lệ',
                        style: TextStyle(color: Colors.white)));
              }

              if (state.isDataReady) {
                scrollToIndex(state.hourIndex);
              }

              final currentDayWeather =
                  weatherList[WeatherUtils.myLocationIndex].weeklyWeather[0];
              final allTime = currentDayWeather.allTime;
              final airQuality =
                  weatherList[WeatherUtils.myLocationIndex].airQuality;
              final fullDate = DateFormat('EEEE, d MMMM, yyyy', 'vi')
                  .format(DateTime.now())
                  .replaceFirst('Thứ ', 'Thứ ');

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: myWidth,
                        child: Column(
                          children: [
                            SizedBox(
                                height: myHeight * AppConstants.defaultPadding),
                            GestureDetector(
                              onTap: () => _showCitySelectionDialog(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    state.myLocation,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize:
                                            AppConstants.defaultFontSizeLarge),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_drop_down,
                                      color: Colors.white, size: 30),
                                ],
                              ),
                            ),
                            SizedBox(height: myHeight * 0.01),
                            Text(
                              fullDate,
                              style: TextStyle(
                                  fontSize: AppConstants.defaultFontSizeMedium,
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                            SizedBox(height: myHeight * 0.03),
                            Container(
                              height: myHeight * 0.05,
                              width: myWidth * 0.6,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  buildTab(
                                      'Dự báo',
                                      state.isForecastTab,
                                      () => context
                                          .read<WeatherBloc>()
                                          .add(SwitchTab(true))),
                                  buildTab(
                                      'Không khí',
                                      !state.isForecastTab,
                                      () => context
                                          .read<WeatherBloc>()
                                          .add(SwitchTab(false))),
                                ],
                              ),
                            ),
                            SizedBox(height: myHeight * 0.03),
                            state.isForecastTab
                                ? Image.asset(
                                    state.hourIndex >= 0 &&
                                            state.hourIndex <
                                                (allTime?.img?.length ?? 0)
                                        ? allTime!.img[state.hourIndex]
                                        : currentDayWeather.mainImg ??
                                            'assets/img/4.png',
                                    height: myHeight * 0.25,
                                    width: myWidth * 0.8,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.cloud,
                                                size: 100, color: Colors.white),
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
                  Container(
                    height: myHeight * 0.06,
                    child: Row(
                      children: [
                        buildWeatherInfo(
                            'Nhiệt độ',
                            getSafeValue(
                                allTime?.temps, state.hourIndex, '°C')),
                        buildWeatherInfo(
                            'Gió',
                            getSafeValue(
                                allTime?.wind, state.hourIndex, ' km/h')),
                        buildWeatherInfo(
                            'Độ ẩm',
                            getSafeValue(
                                allTime?.humidities, state.hourIndex, '%')),
                      ],
                    ),
                  ),
                  SizedBox(height: myHeight * 0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: myWidth * 0.06),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Hôm nay',
                            style:
                                TextStyle(color: Colors.white, fontSize: 28)),
                        GestureDetector(
                          onTap: widget.onViewForecast,
                          child: const Text('Xem báo cáo đầy đủ',
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: AppConstants.defaultFontSizeSmall)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: myHeight * 0.01),
                  Container(
                    height: myHeight * 0.15,
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: myWidth * 0.03, bottom: myHeight * 0.03),
                      child: allTime?.hour?.isNotEmpty ?? false
                          ? ScrollablePositionedList.builder(
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: allTime!.hour.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () => context
                                      .read<WeatherBloc>()
                                      .add(SelectHour(index)),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: myWidth * 0.02,
                                        vertical: myHeight * 0.01),
                                    child: Container(
                                      width: myWidth * 0.35,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color: state.hourIndex == index
                                            ? null
                                            : Colors.white.withOpacity(0.05),
                                        gradient: state.hourIndex == index
                                            ? const LinearGradient(colors: [
                                                AppConstants.gradientStart,
                                                AppConstants.gradientEnd
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
                                                  const Icon(Icons.cloud,
                                                      color: Colors.white,
                                                      size: 24),
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
                                                        fontSize: AppConstants
                                                            .defaultFontSizeSmall,
                                                        color: Colors.white),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Text(
                                                    '${allTime.temps[index].toStringAsFixed(1)}°C',
                                                    style: const TextStyle(
                                                        fontSize: 22,
                                                        color: Colors.white),
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
                              child: Text('Không có dữ liệu thời tiết theo giờ',
                                  style: TextStyle(color: Colors.white))),
                    ),
                  ),
                  SizedBox(height: myHeight * AppConstants.defaultPadding),
                ],
              );
            }

            if (state is WeatherError) {
              return Center(
                  child: Text('Lỗi: ${state.message}',
                      style: const TextStyle(color: Colors.white)));
            }

            return const Center(
                child: Text('Nhấn để tải dữ liệu',
                    style: TextStyle(color: Colors.white)));
          },
        ),
      ),
    );
  }
}
