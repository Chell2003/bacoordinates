import 'dart:io';

import 'package:flutter/material.dart';

class NoInternet extends StatefulWidget {
  const NoInternet({super.key});

  @override
  _NoInternetState createState() => _NoInternetState();
}

class _NoInternetState extends State<NoInternet> {
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _checkInternet();
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        setState(() {
          _hasInternet = true;
        });
      } else {
        setState(() {
          _hasInternet = false;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _hasInternet
                ? const Text('You have internet')
                : const Text('No internet connection'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkInternet,
              child: const Text('Check internet'),
            ),
          ],
        ),
      ),
    );
  }
}