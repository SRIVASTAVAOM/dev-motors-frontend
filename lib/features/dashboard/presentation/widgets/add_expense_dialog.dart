import 'package:flutter/material.dart';
import '../../../../core/constants/expense_categories.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/services/api_service.dart';

class AddExpenseDialog extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSubmit;
  final VoidCallback? onCreated;

  const AddExpenseDialog({super.key, this.onSubmit, this.onCreated});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = ExpenseCategories.names.first;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _vehicleNoController = TextEditingController();
  String? _base64Receipt;
  String? _receiptName;
  bool _isLoading = false;

  Future<void> _handleSubmission() async {
    if (!_formKey.currentState!.validate()) return;

    final data = {
      "category": _selectedCategory,
      "amount": double.tryParse(_amountController.text.trim()) ?? 0,
      "description": _descriptionController.text.trim(),
      "vehicleNumber": _vehicleNoController.text.trim(),
      "receiptImage": _base64Receipt,
    };

    if (widget.onSubmit != null) {
      widget.onSubmit!(data);
      Navigator.pop(context);
    } else {
      setState(() => _isLoading = true);
      try {
        await ApiService.createExpense(
          category: _selectedCategory,
          amount: double.tryParse(_amountController.text.trim()) ?? 0,
          description: _descriptionController.text.trim(),
          vehicleNumber: _vehicleNoController.text.trim(),
          receiptImage: _base64Receipt,
        );
        if (mounted) {
          Navigator.pop(context);
          widget.onCreated?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Claim submitted successfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error submitting claim: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_shopping_cart, color: Color(0xff2563EB)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "New Expense Claim",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Category", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ExpenseCategories.names.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 16),
                const Text("Amount (₹)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "e.g. 1500",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter amount" : null,
                ),
                const SizedBox(height: 16),
                const Text("Description / Purpose", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: "e.g. Fuel for customer vehicle transit",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter purpose" : null,
                ),
                const SizedBox(height: 16),
                const Text("Vehicle / Job Card No (Optional)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _vehicleNoController,
                  decoration: InputDecoration(
                    hintText: "e.g. UP78-XX-1234",
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final res = await ImagePickerHelper.showImageSourceDialog(context);
                    if (res != null) {
                      setState(() {
                        _base64Receipt = res;
                        _receiptName = "Receipt_${DateTime.now().millisecondsSinceEpoch}.jpg";
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: _base64Receipt != null ? Colors.green : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: _base64Receipt != null ? Colors.green.shade50 : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _base64Receipt != null ? Icons.check_circle : Icons.attach_file,
                          color: _base64Receipt != null ? Colors.green : Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _receiptName ?? "Attach Bill (Camera / Gallery)",
                            style: TextStyle(
                              color: _base64Receipt != null ? Colors.green.shade800 : Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleSubmission,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Submit Claim", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
