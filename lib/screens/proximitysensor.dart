// ignore_for_file: library_private_types_in_public_api, use_super_parameters, avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ndobasmarthomesensormobileapp/components/ThemeProvider.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: MaterialApp(
        home: ProximityPage(key: UniqueKey()), // Wrap with MaterialApp
      ),
    ),
  ));
}

class ProximityPage extends StatefulWidget {
  const ProximityPage({Key? key}) : super(key: key);

  @override
  _ProximityPageState createState() => _ProximityPageState();
}

class _ProximityPageState extends State<ProximityPage> {
  bool _isNear = false;
  late StreamSubscription<int> _proximitySubscription;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _notificationSent = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    listenSensor();
  }

  @override
  void dispose() {
    _proximitySubscription.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'Proximity_channel',
      'Proximity Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Motion Detected',
      message,
      platformChannelSpecifics,
    );
    print('Notification sent: $message');
    _notificationSent = true;
  }

  Future<void> listenSensor() async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    _proximitySubscription = ProximitySensor.events.listen((int event) {
      print('Proximity sensor value: $event');
      setState(() {
        _isNear = event == 1;
        print('setState called. Is near: $_isNear');
        if (_isNear && !_notificationSent) {
          themeNotifier.toggleTheme();
          _showNotification('Motion detected: Device is close!');
          _notificationSent = true;
        } else if (!_isNear) {
          _notificationSent = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.hintColor,
        title: Text(
          'Motion Sensor',
          style: TextStyle(color: theme.primaryColor),
        ),
        iconTheme: IconThemeData(
          color: theme.primaryColor, // This sets the back arrow color
        ),
      ),
      body: Container(
        color: theme.primaryColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isNear ? 'You are close!' : 'Get Near To Change Theme',
                style: TextStyle(color: theme.hintColor),
              ),
              Lottie.asset(
                'lib/assets/Animation - 1712058538433.json',
                width: 400,
                height: 400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
