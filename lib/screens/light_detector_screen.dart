import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:sensors/sensors.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'brightness_manager.dart';

class Light extends StatefulWidget {
  Light({Key? key}) : super(key: key);

  @override
  _LightState createState() => _LightState();
}

class _LightState extends State<Light> {
  double brightness = 0.0;
  bool toggle = false;
  late StreamSubscription<AccelerometerEvent> _subscription;
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    getBrightness();
    proximityListener();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  void _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'light_channel', // Change this to match your channel ID
      'Light Notifications', // Replace with your own channel name
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  void getBrightness() async {
    double bright;
    try {
      bright = await FlutterScreenWake.brightness;
    } on PlatformException {
      bright = 1.0;
    }
    if (!mounted) return;

    setState(() {
      brightness = bright;
    });
    setScreenBrightness(brightness);
    BrightnessManager.instance.setBrightness(brightness);
  }

  void setScreenBrightness(double value) {
    FlutterScreenWake.setBrightness(value);
  }

  void proximityListener() {
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (event.z > 8.0) {
        autoAdjustBrightness(0.1);
        _showNotification('Light Intensity Low', 'The surrounding light intensity is low.');
      } else {
        autoAdjustBrightness(1.0);
        _showNotification('Light Intensity High', 'The surrounding light intensity is high.');
      }
    });
  }

  void autoAdjustBrightness(double targetBrightness) {
    final double changeSpeed = 0.001; // Adjusted for slower speed
    double difference = targetBrightness - brightness;
    if (difference.abs() < changeSpeed) {
      setState(() {
        brightness = targetBrightness;
        setScreenBrightness(brightness);
        BrightnessManager.instance.setBrightness(brightness);
      });
    } else {
      Timer.periodic(Duration(milliseconds: 10), (timer) {
        if ((targetBrightness - brightness).abs() < changeSpeed) {
          timer.cancel();
        } else {
          setState(() {
            brightness += difference > 0 ? changeSpeed : -changeSpeed;
            setScreenBrightness(brightness);
            BrightnessManager.instance.setBrightness(brightness);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Sensor'),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.lightGreenAccent,
            border: Border.all(color: Colors.black26),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 2,
                blurRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Brightness:'),
              const SizedBox(height: 10),
              Row(
                children: [
                  AnimatedCrossFade(
                    firstChild: const Icon(Icons.brightness_7, size: 50),
                    secondChild: const Icon(Icons.brightness_3, size: 50),
                    crossFadeState: toggle
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(seconds: 1),
                  ),
                  Expanded(
                    child: Slider(
                      value: brightness,
                      onChanged: (value) {
                        setState(() {
                          brightness = value;
                          setScreenBrightness(brightness);
                          BrightnessManager.instance.setBrightness(brightness);
                        });
                      },
                    ),
                  ),
                ],
              ),
              Text(
                brightnessPercentage(),
                style: TextStyle(fontSize: 16.0),
              )
            ],
          ),
        ),
      ),
    );
  }

  String brightnessPercentage() {
    int percentage = (brightness * 100).round();
    return '$percentage%';
  }
}
