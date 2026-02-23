import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../core/error_handler.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _registerNoController = TextEditingController();
  final _phoneController = TextEditingController();

  UserRole? _selectedRole;
  String? _selectedDept;
  String? _selectedSemester;

  final List<String> _semesters = ["1", "2", "3", "4", "5", "6", "7", "8"];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Profile"),
        actions: [
          IconButton(
            onPressed: () => authProvider.logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Create your profile to continue",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Designation / Role",
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.label),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() {
                    _selectedRole = val;
                    // Reset department and semester if role changes
                    _selectedDept = null;
                    _selectedSemester = null;
                  }),
                  validator: (val) => val == null ? "Required" : null,
                ),
                const SizedBox(height: 16),
                // Show Department only if role is choose and not Security
                if (_selectedRole != null && _selectedRole != UserRole.security)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDept,
                      decoration: const InputDecoration(
                        labelText: "Department",
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      items:
                          (_selectedRole == UserRole.hod
                                  ? ["ECE", "CSE", "CIVIL", "ERE"]
                                  : ["ECE", "CSE 1", "CSE 2", "CIVIL", "ERE"])
                              .map((dept) {
                                return DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept),
                                );
                              })
                              .toList(),
                      onChanged: (val) => setState(() => _selectedDept = val),
                      validator: (val) => val == null ? "Required" : null,
                    ),
                  ),
                // Show Semester only for Students
                if (_selectedRole == UserRole.student)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedSemester,
                      decoration: const InputDecoration(
                        labelText: "Semester",
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: _semesters.map((sem) {
                        return DropdownMenuItem(
                          value: sem,
                          child: Text("Semester $sem"),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSemester = val),
                      validator: (val) => val == null ? "Required" : null,
                    ),
                  ),
                TextFormField(
                  controller: _registerNoController,
                  decoration: const InputDecoration(
                    labelText: "Register Number / Employee ID",
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) =>
                      val == null || val.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await authProvider.completeProfile(
                                name: _nameController.text.trim(),
                                role: _selectedRole!,
                                department: _selectedRole == UserRole.security
                                    ? "Security"
                                    : (_selectedDept ?? "Unknown"),
                                registerNumber: _registerNoController.text
                                    .trim(),
                                phone: _phoneController.text.trim(),
                                semester: _selectedSemester,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AuthErrorHandler.getMessage(e),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: authProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Create Profile"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
