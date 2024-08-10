import 'package:flutter/material.dart';
import 'package:ndobasmarthomesensormobileapp/screens/accelerometer_dashboard.dart';
import 'package:ndobasmarthomesensormobileapp/screens/light_detector_screen.dart';
import 'package:provider/provider.dart';
import 'package:ndobasmarthomesensormobileapp/components/ThemeProvider.dart';
import 'package:ndobasmarthomesensormobileapp/screens/StepCounter.dart';
import 'package:ndobasmarthomesensormobileapp/screens/compass.dart';
import 'package:ndobasmarthomesensormobileapp/screens/lightsensor.dart';
import 'package:ndobasmarthomesensormobileapp/screens/maps.dart';
import 'package:ndobasmarthomesensormobileapp/screens/proximitysensor.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
  await initNotifications();
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
      // Handle notification tap
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Mobile App',
      theme: themeNotifier.currentTheme,
      home: const MyHomePage(title: 'Welcome Cedrick'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          widget.title,
          style: TextStyle(color: theme.primaryColor),
        ),
      ),
      backgroundColor: Colors.black12, // Set background color to grey
      body: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildButton(
            context,
            Icons.color_lens,
            'Themes',
                () => themeNotifier.toggleTheme(),
          ),
          _buildButton(
            context,
            Icons.explore,
            'Compass',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => CompassPage())),
          ),
          _buildButton(
            context,
            Icons.gps_fixed,
            'GPS',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => MapPagez())),
          ),
          _buildButton(
            context,
            Icons.light_mode,
            'Brightness Sensor',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => Light())),
          ),
          _buildButton(
            context,
            Icons.run_circle,
            'Footstep Counter',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => StepCounterPage())),
          ),
          _buildButton(
            context,
            Icons.sensor_window,
            'Motion Detector',
                () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => AccelerometerDashboard())),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80, // Adjust size as needed
        height: 80, // Adjust size as needed
        decoration: BoxDecoration(
          color: Colors.grey, // Set button color to blue
          shape: BoxShape.circle, // Make the button circular
          border: Border.all(
            color: Colors.white, // Set border color to white
            width: 2, // Set border width
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.black), // Adjust icon color to pink
              SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold), // Adjust text color to white
              ),
            ],
          ),
        ),
      ),
    );
  }
}
