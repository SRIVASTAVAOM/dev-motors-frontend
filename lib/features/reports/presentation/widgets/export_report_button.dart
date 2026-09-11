import 'package:flutter/material.dart';

class ExportReportButton extends StatelessWidget {
  const ExportReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.download),
        label: const Text(
          "Export Report",
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Export feature coming soon"),
            ),
          );
        },
      ),
    );
  }
}