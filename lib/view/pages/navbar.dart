// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:trinh_van_hao/view/pages/forecast.dart';
import 'package:trinh_van_hao/view/pages/home.dart';
import 'package:trinh_van_hao/view/pages/search.dart';
import 'package:trinh_van_hao/view/pages/setting.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;
  Widget _currentPage = const Home(); // Mặc định là Home

  void changePage(Widget page, int index) {
    setState(() {
      _currentPage = page;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double myHeight = MediaQuery.of(context).size.height;
    double myWidth = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xff060720),
        body: _currentPage,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: const Color(0xff060720),
          currentIndex: _currentIndex,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: (value) {
            setState(() {
              _currentIndex = value;
              switch (value) {
                case 0:
                  _currentPage = Home(
                    onViewForecast: () => changePage(const Forecast(), 2),
                  );
                  break;
                case 1:
                  _currentPage = const Search();
                  break;
                case 2:
                  _currentPage = const Forecast();
                  break;
                case 3:
                  _currentPage = const Setting();
                  break;
              }
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/1.2.png',
                height: myHeight * 0.03,
                color: Colors.grey.withOpacity(0.5),
              ),
              label: '',
              activeIcon: Image.asset(
                'assets/icons/1.1.png',
                height: myHeight * 0.03,
                color: Colors.white,
              ),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/2.2.png',
                height: myHeight * 0.03,
                color: Colors.grey.withOpacity(0.5),
              ),
              label: '',
              activeIcon: Image.asset(
                'assets/icons/2.1.png',
                height: myHeight * 0.03,
                color: Colors.white,
              ),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/3.2.png',
                height: myHeight * 0.03,
                color: Colors.grey.withOpacity(0.5),
              ),
              label: '',
              activeIcon: Image.asset(
                'assets/icons/3.1.png',
                height: myHeight * 0.03,
                color: Colors.white,
              ),
            ),
            BottomNavigationBarItem(
              icon: Image.asset(
                'assets/icons/4.2.png',
                height: myHeight * 0.03,
                color: Colors.grey.withOpacity(0.5),
              ),
              label: '',
              activeIcon: Image.asset(
                'assets/icons/4.1.png',
                height: myHeight * 0.03,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
