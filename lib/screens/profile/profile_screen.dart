import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _deptController;
  late TextEditingController _regController;
  late TextEditingController _semController;

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AuthProvider>().userProfile ?? {};
    _nameController = TextEditingController(text: profile['name']);
    _phoneController = TextEditingController(text: profile['phone']);
    _deptController = TextEditingController(text: profile['department']);
    _regController = TextEditingController(text: profile['registerNumber']);
    _semController = TextEditingController(text: profile['semester']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _regController.dispose();
    _semController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _deptController.text.trim(),
        'semester': _semController.text.trim(),
        'registerNumber': _regController.text.trim(),
      };

      try {
        await context.read<AuthProvider>().updateProfile(data);
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.userProfile ?? {};
    final role = auth.userRole?.name.toUpperCase() ?? "USER";

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            "Profile",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                onPressed: () => setState(() => _isEditing = true),
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.error),
                onPressed: () => setState(() => _isEditing = false),
              ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.1),
                              width: 4,
                            ),
                            image: const DecorationImage(
                              image: AssetImage('asset/playstore.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile['name'] ?? "User Name",
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      profile['email'] ?? "email@example.com",
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Personal Information"),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        label: "Full Name",
                        icon: Icons.person_outline_rounded,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: "Phone Number",
                        icon: Icons.phone_outlined,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Academic Details"),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _deptController,
                        label: "Department",
                        icon: Icons.school_outlined,
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _semController,
                              label: "Semester",
                              icon: Icons.grid_view_rounded,
                              enabled: _isEditing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _regController,
                              label: "Reg. No",
                              icon: Icons.badge_outlined,
                              enabled: _isEditing,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      if (_isEditing)
                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: auth.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : Text(
                                  "Save Changes",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary.withOpacity(0.7),
            size: 20,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.withOpacity(0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }
}
