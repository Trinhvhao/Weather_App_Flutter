// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trinh_van_hao/bloc/weather_bloc.dart';
import 'package:trinh_van_hao/bloc/weather_event.dart';
import 'package:trinh_van_hao/bloc/weather_state.dart';
import 'package:trinh_van_hao/utils/weather_utils.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff060720),
        body: Container(
          height: myHeight,
          width: myWidth,
          child: Column(
            children: [
              SizedBox(height: myHeight * 0.03),
              const Text(
                'Pick location',
                style: TextStyle(fontSize: 30, color: Colors.white),
              ),
              SizedBox(height: myHeight * 0.03),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: myWidth * 0.05),
                child: Column(
                  children: [
                    Text(
                      'Tìm thời tiết thành phố muốn theo dõi',
                      style: TextStyle(
                          fontSize: 18, color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: myHeight * 0.05),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: myWidth * 0.06),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: myWidth * 0.05),
                          child: TextFormField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              icon: Image.asset(
                                'assets/icons/2.2.png',
                                height: myHeight * 0.025,
                                color: Colors.white.withOpacity(0.5),
                              ),
                              hintText: 'Search',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: myWidth * 0.03),
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: myHeight * 0.013),
                          child: Center(
                            child: Image.asset(
                              'assets/icons/6.png',
                              height: myHeight * 0.03,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: myHeight * 0.04),
              Expanded(
                child: BlocBuilder<WeatherBloc, WeatherState>(
                  builder: (context, state) {
                    if (state is WeatherLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is WeatherLoaded) {
                      final weatherList = state.weatherList
                          .where((weather) => weather.name!
                              .toLowerCase()
                              .contains(_searchQuery))
                          .toList();

                      if (weatherList.isEmpty) {
                        return const Center(
                          child: Text(
                            'No cities found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return GridView.custom(
                        padding:
                            EdgeInsets.symmetric(horizontal: myWidth * 0.05),
                        gridDelegate: SliverStairedGridDelegate(
                          mainAxisSpacing: 13,
                          startCrossAxisDirectionReversed: false,
                          pattern: const [
                            StairedGridTile(0.5, 3 / 2.2),
                            StairedGridTile(0.5, 3 / 2.2),
                          ],
                        ),
                        childrenDelegate: SliverChildBuilderDelegate(
                          childCount: weatherList.length,
                          (context, index) {
                            final weather = weatherList[index];
                            final weeklyWeather = weather.weeklyWeather[0];

                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: myWidth * 0.03),
                              child: GestureDetector(
                                onTap: () {
                                  context
                                      .read<WeatherBloc>()
                                      .add(SelectCity(weather.name!));
                                  Navigator.pushReplacementNamed(
                                      context, '/navbar');
                                },
                                onLongPress: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: const Color(0xff060720),
                                    builder: (context) => Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            weather.name ?? 'N/A',
                                            style: const TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Nhiệt độ: ${weeklyWeather.avgTemp?.toStringAsFixed(1) ?? 'N/A'}°C',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                          Text(
                                            'Độ ẩm: ${weeklyWeather.allTime?.humidities[0] ?? 'N/A'}%',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                          Text(
                                            'Tốc độ gió: ${weeklyWeather.allTime?.wind[0] ?? 'N/A'} m/s',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                          Text(
                                            'Mô tả: ${weeklyWeather.description ?? 'N/A'}',
                                            style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: state.myLocation == weather.name
                                        ? null
                                        : Colors.white.withOpacity(0.05),
                                    gradient: state.myLocation == weather.name
                                        ? const LinearGradient(colors: [
                                            Color.fromARGB(255, 21, 85, 169),
                                            Color.fromARGB(255, 44, 162, 246),
                                          ])
                                        : null,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                weather.name ?? 'N/A',
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Image.asset(
                                              getWeatherIcon(
                                                  weeklyWeather.description ??
                                                      ''),
                                              height: myHeight * 0.06,
                                              width: myWidth * 0.15,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(
                                                Icons.cloud,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: myHeight * 0.01),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${weeklyWeather.avgTemp?.toStringAsFixed(1) ?? 'N/A'}°C',
                                                style: const TextStyle(
                                                    fontSize: 20,
                                                    color: Colors.white),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: myHeight * 0.01),
                                              Text(
                                                weeklyWeather.description ??
                                                    'N/A',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white
                                                        .withOpacity(0.5)),
                                                maxLines: 2,
                                                overflow: TextOverflow.visible,
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
                        'No data available',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
