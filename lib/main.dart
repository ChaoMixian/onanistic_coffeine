// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/record_page.dart';
import 'pages/settings_page.dart';
import 'services/options_service.dart'; // 导入服务

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

// 将 main 函数变为 async
Future<void> main() async {
  // 确保 Flutter 绑定已初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 在 runApp 之前初始化 OptionsService
  await OptionsService().init();
  runApp(HealthHabitApp());
}

class HealthHabitApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: '手冲咖啡',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: AppBarTheme(
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: AppBarTheme(
              elevation: 0,
            ),
          ),
          themeMode: currentMode,
          home: MainNavigationPage(),
        );
      },
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  @override
  _MainNavigationPageState createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    HomePage(),
    RecordPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: '记录',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}