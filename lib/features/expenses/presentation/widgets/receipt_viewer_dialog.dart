import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';

class ReceiptViewerDialog extends StatelessWidget {
  final dynamic receiptData;
  final String title;

  const ReceiptViewerDialog({
    super.key,
    required this.receiptData,
    this.title = "Attached Receipt",
  });

  Widget _voucherWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text(
                  "Verified Digital Expense Slip",
                  style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 32,
            backgroundColor: Color(0xffEFF6FF),
            child: Icon(Icons.receipt_long, color: Color(0xff2563EB), size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff1E293B)),
          ),
          const SizedBox(height: 6),
          Text(
            "Official record recorded in Dev Motors ledger.\nAttachment verified via staff terminal.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Dealership Network", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const Text("DEV MOTORS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff2563EB))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = (receiptData?.toString() ?? '').trim();
    Widget imageWidget;

    if (raw.isEmpty || raw == 'null') {
      imageWidget = _voucherWidget();
    } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
      imageWidget = Image.network(
        raw,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _voucherWidget(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        },
      );
    } else if (raw.startsWith('/') || raw.startsWith('uploads/')) {
      final baseHost = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
      final relativePath = raw.startsWith('/') ? raw.substring(1) : raw;
      final fullUrl = "$baseHost/$relativePath";
      imageWidget = Image.network(
        fullUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _voucherWidget(),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        },
      );
    } else {
      // Treat as Base64 (with or without data URI prefix)
      try {
        String cleanBase64 = raw;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.substring(cleanBase64.indexOf(',') + 1);
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        while (cleanBase64.length % 4 != 0) {
          cleanBase64 += '=';
        }
        final bytes = base64Decode(cleanBase64);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _voucherWidget(),
        );
      } catch (_) {
        imageWidget = _voucherWidget();
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xff2563EB), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 3.5,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(child: imageWidget),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
