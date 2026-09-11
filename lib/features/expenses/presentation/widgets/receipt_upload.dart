import 'package:flutter/material.dart';

class ReceiptUpload extends StatefulWidget {
  final VoidCallback? onUploaded;
  final VoidCallback? onRemoved;

  const ReceiptUpload({
    super.key,
    this.onUploaded,
    this.onRemoved,
  });

  @override
  State<ReceiptUpload> createState() => _ReceiptUploadState();
}

class _ReceiptUploadState extends State<ReceiptUpload> {
  bool uploaded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Icon(
            uploaded
                ? Icons.check_circle
                : Icons.cloud_upload_outlined,
            size: 55,
            color: uploaded ? Colors.green : Colors.blue,
          ),

          const SizedBox(height: 15),

          Text(
            uploaded
                ? "Receipt Uploaded Successfully"
                : "Upload Expense Receipt",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            uploaded
                ? "You can replace or remove the receipt."
                : "Attach Image, Invoice or Bill",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    uploaded = true;
                  });

                  widget.onUploaded?.call();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Receipt selected"),
                    ),
                  );
                },
                icon: const Icon(Icons.photo),
                label: const Text("Gallery"),
              ),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    uploaded = true;
                  });

                  widget.onUploaded?.call();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Receipt selected"),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),

              if (uploaded)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      uploaded = false;
                    });

                    widget.onRemoved?.call();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Remove"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
