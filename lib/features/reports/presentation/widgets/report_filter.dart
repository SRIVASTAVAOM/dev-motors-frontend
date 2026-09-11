import 'package:flutter/material.dart';

class ReportFilter extends StatelessWidget {
  const ReportFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: "This Month",
      decoration: InputDecoration(
        labelText: "Filter",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: "Today",
          child: Text("Today"),
        ),
        DropdownMenuItem(
          value: "This Week",
          child: Text("This Week"),
        ),
        DropdownMenuItem(
          value: "This Month",
          child: Text("This Month"),
        ),
        DropdownMenuItem(
          value: "This Year",
          child: Text("This Year"),
        ),
      ],
      onChanged: (_) {},
    );
  }
}