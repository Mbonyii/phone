import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:sensors_plus/sensors_plus.dart';

class AccelerometerDashboard extends StatefulWidget {
  const AccelerometerDashboard({Key? key}) : super(key: key);

  @override
  _AccelerometerDashboardState createState() => _AccelerometerDashboardState();
}

class _AccelerometerDashboardState extends State<AccelerometerDashboard> {
  late List<double> _accelerometerValues;
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  bool _isMoving = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _accelerometerValues = [0.0, 0.0, 0.0];

    _initializeNotifications();
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = [event.x, event.y, event.z];
            _handleMovementDetection();
          });
        });
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  void _initializeNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _handleMovementDetection() {
    final isMoving = _isDeviceMoving();
    if (isMoving && !_isMoving) {
      // Movement has started
      print('Motion Detected'); // Logging
      _showNotification('Motion Detected');
      _isMoving = true;
    } else if (!isMoving && _isMoving) {
      // Movement has stopped
      _isMoving = false;
    }
  }

  bool _isDeviceMoving() {
    final magnitude = (_accelerometerValues[0].abs() +
        _accelerometerValues[1].abs() +
        _accelerometerValues[2].abs()) /
        3.0;
    print('Magnitude: $magnitude'); // Logging
    return magnitude > 0.05; // Adjust this threshold based on sensitivity
  }

  void _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'Accelerometer_channel',
      'Accelerometer Notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Motion Alert',
      message,
      platformChannelSpecifics,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accelerometer Dashboard'),
        backgroundColor: Colors.lightGreenAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            CircularPercentIndicator(
              radius: 200.0,
              lineWidth: 20.0,
              percent: _calculateMovementPercent(),
              center: Text(
                '${(_calculateMovementPercent() * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              progressColor: Colors.yellowAccent,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildSensorCard('X', _accelerometerValues[0]),
                _buildSensorCard('Y', _accelerometerValues[1]),
                _buildSensorCard('Z', _accelerometerValues[2]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateMovementPercent() {
    final magnitude = (_accelerometerValues[0].abs() +
        _accelerometerValues[1].abs() +
        _accelerometerValues[2].abs()) /
        3.0;
    return (magnitude / 10.0).clamp(0.0, 1.0);
  }

  Widget _buildSensorCard(String title, double value) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              value.toStringAsFixed(2),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: AccelerometerDashboard(),
  ));
}
