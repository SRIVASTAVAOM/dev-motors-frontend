import "../../../../core/utils/image_picker_helper.dart";
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/receipt_helper.dart';

class AddExpenseDialog extends StatefulWidget {
  final VoidCallback onExpenseAdded;
  const AddExpenseDialog({super.key, required this.onExpenseAdded});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  String? _selectedCategory;
  List<dynamic> _categories = [];
  bool _loading = false;
  bool _categoriesLoading = true;
  Map<String, dynamic>? _pickedReceipt;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() async {
            final data = await ImagePickerHelper.showImageSourceDialog(context);
            if (data == null) return;

    try {
      final cats = await ApiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          if (_categories.isNotEmpty) {
            _selectedCategory = _categories[0]['id'];
          }
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  void _pickReceipt(ImageSource source) async {
    final receipt = await ReceiptHelper.pickReceiptImage(source: source);
    if (receipt != null && mounted) {
      setState(() {
        _pickedReceipt = receipt;
      });
    }
  }

  void _submit() async {
    final amountText = _amountCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (amountText.isEmpty || double.tryParse(amountText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _loading = true);

    final res = await ApiService.createExpense(
      amount: double.parse(amountText),
      description: desc.isNotEmpty ? desc : 'Expense Claim',
      categoryId: _selectedCategory!,
      receiptUrl: _pickedReceipt?['base64'],
      receiptFileName: _pickedReceipt?['fileName'],
      receiptMimeType: _pickedReceipt?['mimeType'],
      receiptSize: _pickedReceipt?['size'],
    );

    if (mounted) {
      setState(() => _loading = false);
      if (res['success'] == true) {
        Navigator.pop(context);
        widget.onExpenseAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Expense claim submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(res['message'] ?? 'Failed to submit claim')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: Color(0xff2563EB)),
          SizedBox(width: 8),
          Text('New Expense Claim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            if (_categoriesLoading)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Expense Category',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Description / Purpose',
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            
            const SizedBox(height: 12),
            TextField(
              controller: _vehicleCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "Vehicle / Job Card No (Optional)",
                hintText: "e.g. UP 78 DB 1234 or JC-9921",
                prefixIcon: const Icon(Icons.directions_car_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Attach Bill / Receipt',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff334155)),
            ),
            const SizedBox(height: 8),

            // Direct Camera & Gallery Action Buttons
            if (_pickedReceipt == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickReceipt(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Color(0xff2563EB), size: 18),
                      label: const Text('Camera', style: TextStyle(color: Color(0xff2563EB), fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xff2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickReceipt(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Color(0xff475569), size: 18),
                      label: const Text('Gallery', style: TextStyle(color: Color(0xff475569), fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xffCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedReceipt!['fileName'],
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => setState(() => _pickedReceipt = null),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Claim'),
        ),
      ],
    );
  }
}
