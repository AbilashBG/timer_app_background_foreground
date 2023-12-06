import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? timer;
  int seconds = 0;
  bool isTimerRunning = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String currentTime = "";
  String currentDate = "";
  late String formattedDuration;
  String currentLocation = "";

  int notificationId = 0;

  @override
  void initState() {
    initStateFunctions();

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      /// App is in the background
      showNotification();
    } else if (state == AppLifecycleState.resumed) {
      /// App is in the foreground
      cancelNotification();
    }
  }


  ///fetch GeoLocation

  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks != null && placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = place.name ?? '';
        String city = place.locality ?? '';
        String postalCode = place.postalCode ?? '';
        String state = place.administrativeArea ?? '';
        String country = place.country ?? '';

        return 'Address: $address,\nCity: $city-$postalCode,\nState: $state,\nCountry: $country';
      } else {
        return 'No address found';
      }
    } catch (e) {
      return 'Error getting location: $e';
    }
  }

  ///fetch GeoLocation

  void getLocationNameFromCoordinates(double latitude, double longitude) async {
    String location = await getLocationName(latitude, longitude);
    print('Location: $location');
    currentLocation=location;
    setState(() {});
    // Use the location as needed, for example, display it in a Text widget
  }


  ///from NativeCode

  static const platform = MethodChannel('time_listener');

  ///get systemTime

  Future<String> getSystemTime() async {
    try {
      final String result = await platform.invokeMethod('getSystemTime');
      currentTime = result;
      setState(() {});
      return result;
    } on PlatformException catch (e) {
      return 'Failed to get system time: ${e.message}';
    }
  }

  ///get systemDate

  Future<String> getSystemDate() async {
    try {
      final String result = await platform.invokeMethod('getSystemDate');
      currentDate = result;
      setState(() {});
      return result;
    } on PlatformException catch (e) {
      return 'Failed to get system time: ${e.message}';
    }
  }

  ///functions call in initState

  void initStateFunctions() {
    const settingsAndroid = AndroidInitializationSettings(
      "app_icon",
    );

    const initializationSettings = InitializationSettings(
      android: settingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (payload) async {},
    );

    WidgetsBinding.instance.addObserver(this);
    getSystemDate();
    getSystemTime();
    getCurrentLocation();
    Timer.periodic(const Duration(seconds: 1), (timer) {
      getSystemTime();
      updateNotificationContent();
    });
  }

  ///show content in the notification dialogue

  void updateNotificationContent() async {
    Duration duration = Duration(seconds: seconds);
    formattedDuration = formatDuration(duration);

    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      // Update the notification content if the app is in the background
      await showNotification();
    }
  }

  ///show notification

  Future<void> showNotification() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused) {
      return; // Return if app is not in background
    }

    // Add your notification logic here
    // ...
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your channel id',
      'Channel Name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      sound: RawResourceAndroidNotificationSound('notification_sound'),
      playSound: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Time $currentTime',
      'Timer reached $formattedDuration minutes',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  ///cancel notification

  Future<void> cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }

  ///time in hh:mm:ss formats

  String formatDuration(Duration duration) {
    String hours = (duration.inHours % 60).toString().padLeft(2, '0');
    String minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  ///start the time

  void startTimer() {
    if (!isTimerRunning) {
      timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          seconds++;
        });
      });
      isTimerRunning = true;
    }
  }

  ///stop the time

  void stopTimer() {
    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      getSystemTime();
    });
    if (isTimerRunning) {
      timer?.cancel();
      isTimerRunning = false;
    }
  }

  ///reset the time

  void resetTimer() {
    setState(() {
      seconds = 0; // Reset the timer by setting seconds back to zero
    });
  }

  ///get geoLocation

  String locationMessage = '';

  Future<void> getCurrentLocation() async {
    PermissionStatus permission = await Permission.location.request();
    if (permission == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          locationMessage =
          'Latitude: ${position.latitude}, Longitude: ${position.longitude}';
          getLocationNameFromCoordinates(
              position.latitude, position.longitude);
        });
      } catch (e) {
        print('Error: $e');
        setState(() {
          locationMessage = 'Could not fetch location';
        });
      }
    } else {
      setState(() {
        locationMessage = 'Location permission denied';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    Duration duration = Duration(seconds: seconds);
    formattedDuration = formatDuration(duration);

    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(
                100,
              ),
              border: Border.all(
                width: 2,
                color: Colors.grey.shade800,
              ),
            ),
            child: Center(
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    100,
                  ),
                  border: Border.all(
                    width: 2,
                    color: Colors.grey.shade800,
                  ),
                ),
                child: Center(
                  child: Text(
                    formattedDuration,
                    style: const TextStyle(
                      fontSize: 19,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: size.width,
            margin: const EdgeInsets.symmetric(
              horizontal: 46,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                textButtonWidget("Start", () {
                  startTimer();
                }),
                textButtonWidget("Reset", () {
                  resetTimer();
                }),
                textButtonWidget("Stop", () {
                  stopTimer();
                }),
              ],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          textButtonWidget("Get Location", () {
            getCurrentLocation();
          }),
          const SizedBox(
            height: 13,
          ),
          const SizedBox(
            height: 13,
          ),
          Text("$currentDate - $currentTime"),
          const SizedBox(
            height: 20,
          ),
          Text(locationMessage),
          SizedBox(height: 13,),
          Text(currentLocation),
        ],
      ),
    );
  }
}

Widget textButtonWidget(String text, Function() function) {
  return TextButton(
    onPressed: function,
    child: Text(
      text,
    ),
  );
}
