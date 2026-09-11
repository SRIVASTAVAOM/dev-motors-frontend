import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/api_service.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ManagerApprovalsPage extends StatefulWidget {
  final AuthProvider auth;

  const ManagerApprovalsPage({
    super.key,
    required this.auth,
  });

  @override
  State<ManagerApprovalsPage> createState() =>
      _ManagerApprovalsPageState();
}

class _ManagerApprovalsPageState extends State<ManagerApprovalsPage> {
  bool loading = true;
  List<dynamic> approvals = [];

  static const String baseUrl = ApiService.baseUrl;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/approvals/pending"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.auth.token}",
        },
      );

      debugPrint("APPROVALS STATUS: ${response.statusCode}");
      debugPrint("APPROVALS RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          approvals = data["data"] ?? [];
        });
      } else {
        _showMessage(
          data["message"]?.toString() ?? "Unable to load approvals",
        );
      }
    } catch (e) {
      debugPrint("APPROVALS ERROR: $e");
      _showMessage("Unable to connect to server");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _processApproval({
    required String approvalId,
    required String action,
  }) async {
    final controller = TextEditingController();

    final remarks = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            action == "APPROVE"
                ? "Approve Expense"
                : "Reject Expense",
          ),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: action == "APPROVE"
                  ? "Optional remarks"
                  : "Reason for rejection",
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                if (action == "REJECT" &&
                    controller.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(
                  context,
                  controller.text.trim(),
                );
              },
              child: Text(
                action == "APPROVE" ? "Approve" : "Reject",
              ),
            ),
          ],
        );
      },
    );

    if (remarks == null) return;

    try {
      final response = await http.patch(
        Uri.parse("$baseUrl/approvals/$approvalId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${widget.auth.token}",
        },
        body: jsonEncode({
          "action": action,
          "remarks": remarks,
        }),
      );

      debugPrint("PROCESS STATUS: ${response.statusCode}");
      debugPrint("PROCESS RESPONSE: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        _showMessage(
          action == "APPROVE"
              ? "Expense approved successfully"
              : "Expense rejected successfully",
        );

        await _loadApprovals();
      } else {
        _showMessage(
          data["message"]?.toString() ?? "Action failed",
        );
      }
    } catch (e) {
      debugPrint("PROCESS APPROVAL ERROR: $e");
      _showMessage("Unable to connect to server");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Pending Approvals"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadApprovals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : approvals.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadApprovals,
                  child: ListView(
                    children: const [
                      SizedBox(height: 180),
                      Icon(
                        Icons.check_circle_outline,
                        size: 70,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: Text(
                          "No pending approvals",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadApprovals,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: approvals.length,
                    itemBuilder: (context, index) {
                      final approval = approvals[index];
                      final expense =
                          approval["expense"] ?? {};

                      final employee =
                          expense["employee"] ?? {};

                      final category =
                          expense["category"] ?? {};

                      final location =
                          expense["location"] ?? {};

                      final amount =
                          expense["amount"]?.toString() ?? "0";

                      final status =
                          approval["status"]?.toString() ?? "PENDING";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    child: Icon(Icons.receipt_long),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          employee["name"]?.toString() ??
                                              "Employee",
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          employee["employeeId"]
                                                  ?.toString() ??
                                              "",
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "₹$amount",
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              _infoRow(
                                Icons.category_outlined,
                                "Category",
                                category["name"]?.toString() ??
                                    "Unknown",
                              ),

                              _infoRow(
                                Icons.location_on_outlined,
                                "Location",
                                location["name"]?.toString() ??
                                    "Unknown",
                              ),

                              _infoRow(
                                Icons.description_outlined,
                                "Description",
                                expense["description"]?.toString() ??
                                    "No description",
                              ),

                              _infoRow(
                                Icons.calendar_today_outlined,
                                "Date",
                                expense["expenseDate"]
                                        ?.toString()
                                        .split("T")
                                        .first ??
                                    "",
                              ),

                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        _processApproval(
                                          approvalId:
                                              approval["id"].toString(),
                                          action: "REJECT",
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                      label: const Text(
                                        "Reject",
                                        style: TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        _processApproval(
                                          approvalId:
                                              approval["id"].toString(),
                                          action: "APPROVE",
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.check,
                                      ),
                                      label: const Text("Approve"),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 10),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
