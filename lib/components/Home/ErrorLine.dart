import 'package:flutter/material.dart';

class ErrorLine extends StatelessWidget {
  final String errorMessage;
  
  const ErrorLine({
    super.key,
    this.errorMessage = 'BOTTOM OVERFLOWED BOTTOM OVERFLOWED BOTTOM OVERFLOWED BY 2.0 PIXELS',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        errorMessage,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
} 