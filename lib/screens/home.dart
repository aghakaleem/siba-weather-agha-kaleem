import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:siba_weather/utils/consts.dart';
import 'package:weather/weather.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siba_weather/utils/string_extensions.dart';

class HomeScreen extends StatefulWidget {
  final String userName;

  const HomeScreen({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _homeScreenState();
}

class _homeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final WeatherFactory wf = WeatherFactory(OpenWeather_API_KEY);
  Weather? weather;
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();

    getCurrentCity().then((currCity) {
      fetchWeather(currCity);
    });

    startTimer();
  }

  void fetchWeather(String cityName) async {
    try {
      Weather? fetchedWeather = await wf.currentWeatherByCityName(cityName);
      setState(() {
        weather = fetchedWeather;
      });
    } catch (e) {
      if (mounted) {
        // Check if the widget is still mounted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Timer? _timer;
  void startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      getCurrentCity().then((currCity) {
        fetchWeather(currCity);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: buildUI(),
      ),
    );
  }

  void signOut() async {
    try {
      print("Signing out...");
      await FirebaseAuth.instance.signOut();
      print("Signed out. Navigating to sign-in screen...");
      Navigator.pushReplacementNamed(context, '/signin');
      print("Signed out successfully.");
    } catch (e) {
      // Handle any errors that occur during sign-out
      print("Sign out failed: $e");
    }
  }

  Widget buildUI() {
    int currentHour = DateTime.now().hour;

    // Determine the greeting based on the time of day
    String greeting;
    if (currentHour < 12) {
      greeting = "Good Morning";
    } else if (currentHour < 18) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }

    String firstName = "";
// Check if currentUser is not null
    if (_auth.currentUser != null) {
      // Check if displayName is not null
      if (_auth.currentUser?.displayName != null) {
        final List<String> displayNameParts =
            _auth.currentUser!.displayName!.split(' ');
        firstName = displayNameParts.isNotEmpty ? displayNameParts[0] : '';
        // Continue with your logic using firstName
      } else {
        // Handle the case where displayName is null
        print("DisplayName is null.");
      }
    } else {
      // Handle the case where currentUser is null
      print("Current user is null.");
    }

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.only(top: 20, left: 40, right: 0, bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.07,
                  padding: const EdgeInsets.fromLTRB(10, 10, 9, 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.17),
                        spreadRadius: 0,
                        blurRadius: 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Search for any location',
                      border: InputBorder.none,
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          fetchWeather(_cityController.text);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.more_vert), // This icon can be customized
                onPressed: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(
                        100, 130, 0, 0), // Adjust as needed
                    items: <PopupMenuEntry>[
                      PopupMenuItem<String>(
                        value: 'Sign Out',
                        child: ListTile(
                          title: const Text('Sign Out'),
                          onTap: signOut,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: weather == null
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      Text(
                        "$greeting, ${widget.userName}!",
                        style: GoogleFonts.quicksand(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Colors.black),
                      ),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      locationheader(),
                      dateTimeInfo(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05),
                      weatherIcon(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      currentTemperature(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                      extraInfo(),
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.02),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget locationheader() {
    final String nalo = "${weather?.areaName ?? ""}, ${weather?.country ?? ""}";
    return Text(
      nalo,
      style: GoogleFonts.quicksand(
        fontSize: 47,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget dateTimeInfo() {
    DateTime now = weather!.date!;
    return Column(
      children: [
        const SizedBox(
          height: 5,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              DateFormat("EEEE").format(now),
              style: GoogleFonts.quicksand(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              DateFormat("h:mm a").format(now),
              style: GoogleFonts.quicksand(
                  fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        )
      ],
    );
  }

  Widget weatherIcon() {
    return FutureBuilder<String>(
      future: getWeatherAnimation(
          weather?.weatherMain), // Pass the Future to FutureBuilder
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator while waiting for the future to complete
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle error case
          return Text('Error: ${snapshot.error}');
        } else {
          // Once the future completes, use the result to display the Lottie asset
          return Lottie.asset(snapshot.data!,
              height: MediaQuery.of(context).size.height *
                  0.2); // Use snapshot.data to access the result
        }
      },
    );
  }

  Widget currentTemperature() {
    return Column(
      children: [
        Text(
          "${weather?.temperature?.celsius?.toStringAsFixed(0) ?? ""}°C",
          style:
              GoogleFonts.quicksand(fontSize: 52, fontWeight: FontWeight.w400),
        ),
        Text(
          (weather?.weatherDescription ?? "").capitalize(),
          style: GoogleFonts.quicksand(
              fontSize: 15, color: Colors.black, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }

  Future<String> getWeatherAnimation(String? mainCondition) async {
    double latitude = weather?.latitude ?? 0;
    double longitude = weather?.longitude ?? 0;

    final String url =
        'http://api.openweathermap.org/data/2.5/sunrise-sunset?lat=$latitude&lon=$longitude&appid=$OpenWeather_API_KEY';

    final http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      DateTime sunrise =
          DateTime.fromMillisecondsSinceEpoch(jsonResponse['sunrise'] * 1000);
      DateTime sunset =
          DateTime.fromMillisecondsSinceEpoch(jsonResponse['sunset'] * 1000);

      DateTime currentTime = DateTime.now();

      // Determine if it's currently day or night based on sunrise and sunset times
      bool isDaytime =
          currentTime.isAfter(sunrise) && currentTime.isBefore(sunset);

      if (isDaytime) {
        // Daytime logic
        if (mainCondition == null)
          return 'lib/assets/weatherAnims/dayClear.json';

        switch (mainCondition.toLowerCase()) {
          case 'clouds':
            return 'lib/assets/weatherAnims/dayScatteredClouds.json';
          case 'few clouds':
            return 'lib/assets/weatherAnims/dayFewClouds.json';
          case 'mist':
          case 'fog':
          case 'haze':
          case 'smoke':
          case 'dust':
            return 'lib/assets/weatherAnims/dayMist.json';
          case 'rain':
            return 'lib/assets/weatherAnims/dayRain.json';
          case 'drizzle':
            return 'lib/assets/weatherAnims/dayShowers.json';
          case 'thunderstorm':
            return 'lib/assets/weatherAnims/dayThunderstorm.json';
          case 'snow':
            return 'lib/assets/weatherAnims/daySnow.json';
          case 'clear':
            return 'lib/assets/weatherAnims/dayClear.json';
        }
      }
    } else {
      // Nighttime logic
      if (mainCondition == null)
        return 'lib/assets/weatherAnims/nightClear.json';

      switch (mainCondition.toLowerCase()) {
        // Your nighttime conditions here
        case 'clouds':
          return 'lib/assets/weatherAnims/nightScatteredClouds.json';
        case 'few clouds':
          return 'lib/assets/weatherAnims/nightFewClouds.json';
        case 'mist':
        case 'fog':
        case 'haze':
        case 'smoke':
        case 'dust':
          return 'lib/assets/weatherAnims/nightMist.json';
        case 'rain':
          return 'lib/assets/weatherAnims/nightRain.json';
        case 'drizzle':
          return 'lib/assets/weatherAnims/nightShowers.json';
        case 'thunderstorm':
          return 'lib/assets/weatherAnims/nightThunderstorm.json';
        case 'snow':
          return 'lib/assets/weatherAnims/nightSnow.json';
        case 'clear':
          return 'lib/assets/weatherAnims/nightClear.json';
      }
    }
    throw 'No animation found for weather condition: $mainCondition';
  }

  Widget extraInfo() {
    return Container(
        height: MediaQuery.sizeOf(context).height * 0.15,
        width: MediaQuery.sizeOf(context).width * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFFD6CCFF),
          borderRadius: BorderRadius.circular(
            20,
          ),
        ),
        padding: const EdgeInsets.all(
          8,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Feels Like: ${weather?.tempFeelsLike?.celsius?.toStringAsFixed(0)}°C",
                  style:
                      GoogleFonts.quicksand(fontSize: 15, color: Colors.black),
                ),
                Text(
                  "Clouds: ${weather?.cloudiness?.toStringAsFixed(0)}%",
                  style:
                      GoogleFonts.quicksand(fontSize: 15, color: Colors.black),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Wind: ${(weather?.windSpeed != null ? weather!.windSpeed!.toDouble() * 3.6 : 0).toStringAsFixed(0)} km/h",
                  style:
                      GoogleFonts.quicksand(fontSize: 15, color: Colors.black),
                ),
                Text(
                  "Humidity: ${weather?.humidity?.toStringAsFixed(0)}%",
                  style:
                      GoogleFonts.quicksand(fontSize: 15, color: Colors.black),
                ),
              ],
            )
          ],
        ));
  }

  Future<String> getCurrentCity() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);

    String? cityName = placemarks[0].locality;
    return cityName ?? "";
  }
}
