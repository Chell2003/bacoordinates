import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../components/Home/CustomAppbar.dart';
import '../components/Home/LocationWeatherCard.dart';
import '../components/Home/TabPlace.dart';
import '../components/Home/search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _location = "Fetching location...";
  String _weather = "Loading...";
  int _degree = 0;

  @override
  void initState() {
    super.initState();
    _fetchLocationAndWeather();
  }

  Future<void> _fetchLocationAndWeather() async {
    try {
      Position position = await _determinePosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      String city = placemarks.isNotEmpty ? placemarks[0].locality ?? "Unknown" : "Unknown";

      String apiKey = "6fa0d0348c55330660baa1073a8470f8"; // Replace with your actual API key
      String url =
          "https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&units=metric&appid=$apiKey";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _location = city;
          _weather = data["weather"][0]["main"];
          _degree = data["main"]["temp"].toInt();
        });
      } else {
        setState(() {
          _weather = "Error fetching weather (Code: ${response.statusCode})";
        });
      }
    } catch (e) {
      // setState(() {
      //   _weather = "Error: $e";
      // });
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled.");
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error("Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarExample(),
      body: Column(
        children: [
          LocationWeatherCard(
            location: _location,
            weather: _weather,
            degree: _degree,
          ),
          const Search(),
          const Expanded(
            child: TabPlace(),
          ),
        ],
      ),
    );
  }
}