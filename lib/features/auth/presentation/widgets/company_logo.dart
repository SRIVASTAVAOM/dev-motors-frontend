import 'package:flutter/material.dart';

class CompanyLogo extends StatelessWidget {
  const CompanyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.blue.shade600,
          child: const Icon(
            Icons.directions_car,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          "DEV MOTORS",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Enterprise Expense Management",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
} 