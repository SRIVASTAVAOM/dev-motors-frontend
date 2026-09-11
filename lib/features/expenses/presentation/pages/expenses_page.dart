import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/category_chip.dart';
import '../widgets/expense_card.dart';
import '../widgets/expense_filter.dart';
import '../widgets/expense_search.dart';
import 'add_expense_page.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  static const String baseUrl = ApiService.baseUrl;

  final AuthProvider auth = AuthProvider();

  bool loading = true;
  String? error;
  List<dynamic> expenses = [];

  String selectedCategory = "All";

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // We need the logged-in token.
      //
      // The current app creates AuthProvider inside LoginPage,
      // so first check whether a token is already available.
      String? token = auth.token;
      if (token == null || token.isEmpty) {
        token = await ApiService.getToken();
      }

      if (token.isEmpty) {
        setState(() {
          error = "Authentication token not available";
          loading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/expenses"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      debugPrint("EXPENSES STATUS: ${response.statusCode}");
      debugPrint("EXPENSES RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          expenses = data["data"] ?? [];
        });
      } else {
        setState(() {
          error = data["message"]?.toString() ??
              "Unable to load expenses";
        });
      }
    } catch (e) {
      debugPrint("EXPENSES ERROR: $e");

      setState(() {
        error = "Unable to connect to server";
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  List<dynamic> get filteredExpenses {
    if (selectedCategory == "All") {
      return expenses;
    }

    return expenses.where((expense) {
      final category =
          expense["category"]?["name"]?.toString() ?? "";

      return category.toLowerCase() ==
          selectedCategory.toLowerCase();
    }).toList();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return "";
    }

    try {
      final parsed = DateTime.parse(date).toLocal();

      const months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      return "${parsed.day} ${months[parsed.month - 1]} ${parsed.year}";
    } catch (_) {
      return date;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) {
      return "₹0";
    }

    final value = double.tryParse(amount.toString());

    if (value == null) {
      return "₹$amount";
    }

    return "₹${value.toStringAsFixed(0)}";
  }

  String _categoryForCard(dynamic expense) {
    final category =
        expense["category"]?["name"]?.toString() ?? "Other";

    // Backend category names can be longer than the UI category names.
    if (category.toLowerCase().contains("food")) {
      return "Food";
    }

    if (category.toLowerCase().contains("refresh")) {
      return "Food";
    }

    if (category.toLowerCase().contains("misc")) {
      return "Other";
    }

    return category;
  }

  @override
  Widget build(BuildContext context) {
    final visibleExpenses = filteredExpenses;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        title: const Text("Expense Management"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddExpensePage(),
            ),
          ).then((_) {
            _loadExpenses();
          });
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),

      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ExpenseSearch(),

            const SizedBox(height: 20),

            const ExpenseFilter(),

            const SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip("All"),
                  _categoryChip("Fuel"),
                  _categoryChip("Travel"),
                  _categoryChip("Hotel"),
                  _categoryChip("Repair"),
                  _categoryChip("Food"),
                  _categoryChip("Office"),
                  _categoryChip("Salary"),
                  _categoryChip("Other"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Recent Expenses",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (error != null)
              _errorWidget()
            else if (visibleExpenses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    "No expenses found",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              ...visibleExpenses.map((expense) {
                final category =
                    _categoryForCard(expense);
                final title =
                    expense["description"]?.toString().trim();

                final fallbackTitle =
                    category == "Fuel"
                        ? "Fuel Expense"
                        : category;

                return ExpenseCard(
                  title: title == null || title.isEmpty
                      ? fallbackTitle
                      : title,
                  category: category,
                  amount: _formatAmount(
                    expense["amount"],
                  ),
                  date: _formatDate(
                    expense["expenseDate"]?.toString(),
                  ),
                  status:
                      expense["status"]?.toString() ??
                          "PENDING",
                );
              }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String title) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = title;
          });
        },
        child: CategoryChip(
          title: title,
          selected: selectedCategory == title,
        ),
      ),
    );
  }

  Widget _errorWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loadExpenses,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
