import 'package:cargo_app_driver/auth/analytics.dart';
import 'package:cargo_app_driver/auth/dashboard.dart';
import 'package:cargo_app_driver/auth/settings.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  double _sales = 56700.00;
  bool isSalesToggle = false;
  PageController _pageController = PageController();

  final List<Widget> _pages = [
    const DashboardPage(),
    const AnalyticsPage(),
    const SettingsPage(),
  ];

  void salesToggle() {
    setState(() {
      isSalesToggle = !isSalesToggle;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(
                () {
              _currentIndex = index;
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 23,
        selectedItemColor: Colors.blue,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 247, 247, 247),
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          color: Color.fromARGB(255, 247, 247, 247),
        ),
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(
                () {
              _currentIndex = index;
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.navigation),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Earns',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
