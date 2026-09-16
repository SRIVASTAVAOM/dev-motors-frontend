import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/image_picker_helper.dart';
import '../../../dashboard/presentation/widgets/add_staff_dialog.dart';
import 'change_password_dialog.dart';

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key});

  static void show(BuildContext context, {VoidCallback? onProfileUpdated}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ProfileSheet(),
    ).then((_) {
      if (onProfileUpdated != null) onProfileUpdated();
    });
  }

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = ApiService.currentUser;
      if (mounted) {
        setState(() {
          _user = user;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updatePhoneDialog(String currentPhone) async {
    final controller = TextEditingController(
      text: currentPhone == 'Not Provided' ? '' : currentPhone,
    );
    String? errorText;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.phone_android, color: Color(0xff2563EB)),
                SizedBox(width: 8),
                Text("Update Mobile Number", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Enter your contact mobile number:", style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.phone, size: 20),
                    prefixText: "+91 ",
                    hintText: "9876543210",
                    errorText: errorText,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final raw = controller.text.trim().replaceAll(RegExp(r'\D'), '');
                  if (raw.length < 10) {
                    setDlgState(() => errorText = "Please enter a valid 10-digit number");
                    return;
                  }
                  final newPhone = "+91 $raw";
                  Navigator.pop(ctx);

                  await ApiService.updateProfile(phone: newPhone);
                  await _loadUser();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.green,
                        content: Text("Mobile number updated to $newPhone"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                child: const Text("Save Number"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showAvatarPickerDialog() async {
    final avatarPresets = [
      {'label': 'Executive 1', 'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80'},
      {'label': 'Executive 2', 'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=256&q=80'},
      {'label': 'Corporate 1', 'url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=256&q=80'},
      {'label': 'Corporate 2', 'url': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=256&q=80'},
      {'label': 'Staff 1', 'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=256&q=80'},
      {'label': 'Staff 2', 'url': 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=256&q=80'},
    ];

    final customUrlCtrl = TextEditingController();

    Future<void> saveAvatar(String urlOrBase64, BuildContext ctx) async {
      Navigator.pop(ctx);
      if (mounted) setState(() => _loading = true);
      try {
        await ApiService.updateProfile(avatarUrl: urlOrBase64);
        await _loadUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: urlOrBase64.isEmpty ? Colors.orange : Colors.green,
              content: Text(urlOrBase64.isEmpty ? "Profile picture removed" : "Profile picture updated successfully!"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text("Failed to update profile: $e"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    Future<void> pickImageSource(ImageSource source, BuildContext ctx) async {
      Navigator.pop(ctx);
      try {
        final result = await ImagePickerHelper.pickImage(source);
        if (result != null && result.isNotEmpty) {
          if (mounted) setState(() => _loading = true);
          await ApiService.updateProfile(avatarUrl: result);
          await _loadUser();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.green,
                content: Text("Profile photo updated successfully!"),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Error picking profile image: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text("Could not pick image: $e"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }

    final currentAvatar = (_user?['avatarUrl'] ?? _user?['profileImage'] ?? '').toString().trim();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Update Profile Picture", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text("Take a photo, choose from device, or pick an avatar:", style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 18),

              // Camera and Gallery Quick Option Cards
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => pickImageSource(ImageSource.camera, ctx),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xffBFDBFE), width: 1.2),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xff2563EB),
                              child: Icon(Icons.photo_camera_rounded, color: Colors.white, size: 22),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Take Photo",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff1E40AF)),
                            ),
                            SizedBox(height: 2),
                            Text("Use Camera", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => pickImageSource(ImageSource.gallery, ctx),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xffFAF5FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xffE9D5FF), width: 1.2),
                        ),
                        child: const Column(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(0xff7C3AED),
                              child: Icon(Icons.photo_library_rounded, color: Colors.white, size: 22),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "From Gallery",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff6B21A8)),
                            ),
                            SizedBox(height: 2),
                            Text("Device Storage", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR CHOOSE AVATAR PRESET", style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade200)),
                ],
              ),
              const SizedBox(height: 14),

              SizedBox(
                height: 70,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: avatarPresets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (ctx, idx) {
                    final item = avatarPresets[idx];
                    return InkWell(
                      onTap: () => saveAvatar(item['url']!, ctx),
                      borderRadius: BorderRadius.circular(30),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(item['url']!),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),
              TextField(
                controller: customUrlCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link, size: 20),
                  hintText: "Or paste image web link (https://...)",
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (currentAvatar.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => saveAvatar('', ctx),
                        child: const Text("Remove Photo"),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        final url = customUrlCtrl.text.trim();
                        if (url.isNotEmpty) {
                          saveAvatar(url, ctx);
                        }
                      },
                      child: const Text("Apply URL"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'User';
    final empId = _user?['employeeId'] ?? _user?['id'] ?? 'EMP';
    final role = (_user?['role'] ?? 'STAFF').toString().toUpperCase();
    final location = _user?['location'] is Map ? _user!['location']['name'] : (_user?['branch'] ?? 'Dev Motors');
    final email = _user?['email'] ?? '$empId@devmotors.in';
    final phone = _user?['phone'] ?? _user?['phoneNumber'] ?? _user?['mobile'] ?? 'Not Provided';
    final avatarUrl = (_user?['avatarUrl'] ?? _user?['profileImage'] ?? '').toString().trim();
    final avatarProvider = ImagePickerHelper.getAvatarImageProvider(avatarUrl);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: _loading
          ? const Center(heightFactor: 4, child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: const Color(0xff2563EB).withValues(alpha: 0.1),
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? Text(
                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xff2563EB)),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showAvatarPickerDialog,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xff2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xff2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(color: Color(0xff2563EB), fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 10),
                _buildInfoTile(Icons.badge_outlined, "Employee ID", empId),
                _buildInfoTile(Icons.email_outlined, "Email Address", email),
                _buildInfoTile(
                  Icons.phone_outlined,
                  "Phone Number",
                  phone.toString(),
                  onEdit: () => _updatePhoneDialog(phone.toString()),
                ),
                _buildInfoTile(Icons.location_on_outlined, "Branch Location", location.toString()),
                const SizedBox(height: 20),
                if (role.toUpperCase() == 'OWNER') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text("Add Dealership Staff", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (_) => AddStaffDialog(onStaffCreated: () {}),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xff2563EB),
                      side: const BorderSide(color: Color(0xff2563EB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.key, size: 18),
                    label: const Text("Change Password", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const ChangePasswordDialog(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade600,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await ApiService.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {VoidCallback? onEdit}) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade500),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (onEdit != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 12, color: Color(0xff2563EB)),
                    SizedBox(width: 4),
                    Text("Edit", style: TextStyle(fontSize: 11, color: Color(0xff2563EB), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
