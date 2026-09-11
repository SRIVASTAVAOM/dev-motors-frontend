import 'package:flutter/material.dart';
import '../../../../core/constants/expense_categories.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../../core/services/api_service.dart';

class EditExpenseDialog extends StatefulWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onUpdated;

  const EditExpenseDialog({super.key, required this.expense, required this.onUpdated});

  @override
  State<EditExpenseDialog> createState() => _EditExpenseDialogState();
}

class _EditExpenseDialogState extends State<EditExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _vehicleNoController;
  String? _base64Receipt;
  bool _isLoading = false;

  String _extractString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    if (val is String) return val;
    if (val is Map) {
      return val['name']?.toString() ??
          val['title']?.toString() ??
          val['label']?.toString() ??
          val['category']?.toString() ??
          fallback;
    }
    return val.toString();
  }

  @override
  void initState() {
    super.initState();
    final exp = widget.expense;
    
    // Safe category parsing
    final rawCat = _extractString(exp['category'], ExpenseCategories.names.first);
    if (ExpenseCategories.names.contains(rawCat)) {
      _selectedCategory = rawCat;
    } else {
      _selectedCategory = ExpenseCategories.names.first;
    }

    _amountController = TextEditingController(text: _extractString(exp['amount']));
    _descriptionController = TextEditingController(text: _extractString(exp['description']));
    _vehicleNoController = TextEditingController(text: _extractString(exp['vehicleNumber']));
    
    final r = exp['receiptImage'] ?? exp['receiptUrl'];
    _base64Receipt = r is String ? r : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _vehicleNoController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final id = _extractString(widget.expense['_id'] ?? widget.expense['id']);
      await ApiService.updateExpense(
        expenseId: id,
        category: _selectedCategory,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        description: _descriptionController.text.trim(),
        vehicleNumber: _vehicleNoController.text.trim(),
        receiptImage: _base64Receipt,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Expense claim updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      child: const Icon(Icons.edit_note, color: Color(0xff2563EB)),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Edit Expense Claim",
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
                    return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)));
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? "Please enter purpose" : null,
                ),
                const SizedBox(height: 16),
                const Text("Vehicle / Job Card No", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _vehicleNoController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final res = await ImagePickerHelper.showImageSourceDialog(context);
                    if (res != null) {
                      setState(() => _base64Receipt = res);
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
                            _base64Receipt != null ? "Receipt Attached (Tap to replace)" : "Attach Bill (Camera / Gallery)",
                            style: TextStyle(
                              color: _base64Receipt != null ? Colors.green.shade800 : Colors.blue.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
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
                      onPressed: _isLoading ? null : _handleUpdate,
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
