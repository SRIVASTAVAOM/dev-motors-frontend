import 'package:flutter/material.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Monthly Summary",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 20),

            ListTile(
              leading: Icon(Icons.currency_rupee),
              title: Text("Total Expense"),
              trailing: Text(
                "₹2,36,000",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            Divider(),

            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text("Highest Category"),
              trailing: Text(
                "Fuel",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            Divider(),

            ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text("Total Bills"),
              trailing: Text(
                "184",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}