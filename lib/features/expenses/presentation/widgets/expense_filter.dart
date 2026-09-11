import 'package:flutter/material.dart';

class ExpenseFilter extends StatelessWidget {
  const ExpenseFilter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.calendar_month),
            label: const Text("Date"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text("Filter"),
          ),
        ),
      ],
    );
  }
}