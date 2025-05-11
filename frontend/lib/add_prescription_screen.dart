import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme_constants.dart';
import 'constants.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final String username;
  final String password;
  
  const AddPrescriptionScreen({
    Key? key,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _sideEffectsController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _sideEffectsController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  Future<void> _addPrescription() async {
    if (_medicineNameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _sideEffectsController.text.isEmpty ||
        _frequencyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add-prescription'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'password': widget.password,
          'medicine_name': _medicineNameController.text,
          'recommended_dosage': _dosageController.text,
          'side_effects': _sideEffectsController.text,
          'frequency': int.parse(_frequencyController.text),
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Prescription added successfully'),
              backgroundColor: ThemeConstants.primaryColor,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add prescription: ${response.body}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding prescription: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Prescription',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: ThemeConstants.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),      body: Column(
        children: [          // Top section with modern design
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: ThemeConstants.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ThemeConstants.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background decoration
                  Positioned(
                    right: -30,
                    top: -20,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -50,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.medication_outlined,
                            size: 50,
                            color: ThemeConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Add New Prescription',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your preferred method',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom section with options
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildOptionButton(
                    icon: Icons.camera_alt,
                    title: 'Scan Prescription',
                    subtitle: 'Take a photo of your prescription',
                    onTap: () {
                      // TODO: Implement camera capture
                      _showPrescriptionForm(isPrefilled: true);
                    },
                  ),                  _buildOptionButton(
                    icon: Icons.mic,
                    title: 'Voice Input',
                    subtitle: 'Dictate your prescription details',
                    onTap: _showRecordingModal,
                  ),
                  _buildOptionButton(
                    icon: Icons.edit,
                    title: 'Manual Entry',
                    subtitle: 'Type in prescription details',
                    onTap: () => _showPrescriptionForm(isPrefilled: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ThemeConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: ThemeConstants.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPrescriptionForm({required bool isPrefilled}) {
    // If isPrefilled is true, we would pre-populate the fields with detected/dictated data
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPrefilled ? 'Review Details' : 'Enter Details',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _medicineNameController,
                  label: 'Medicine Name',
                  icon: Icons.medication,
                ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _dosageController,
                label: 'Recommended Dosage',
                icon: Icons.schedule,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _sideEffectsController,
                label: 'Side Effects',
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _frequencyController,
                label: 'Frequency (times per day)',
                icon: Icons.repeat,
                keyboardType: TextInputType.number,
              ),              const SizedBox(height: 16),
              _buildInputField(
                controller: _dosageController,
                label: 'Recommended Dosage',
                icon: Icons.schedule,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _sideEffectsController,
                label: 'Side Effects',
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _frequencyController,
                label: 'Frequency (times per day)',
                icon: Icons.repeat,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  _addPrescription();
                  Navigator.pop(context); // Close the bottom sheet first
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add Prescription',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16), // Add padding for bottom safe area
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // Handle keyboard
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: ThemeConstants.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: ThemeConstants.primaryColor),
          ),
        ),
      ),
    );
  }
  void _showRecordingModal() {
    bool localIsRecording = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Voice Recording',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ThemeConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (localIsRecording ? Colors.red : ThemeConstants.primaryColor).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      iconSize: 48,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          localIsRecording ? Icons.mic : Icons.mic,
                          key: ValueKey<bool>(localIsRecording),
                          color: localIsRecording ? Colors.red : ThemeConstants.primaryColor,
                        ),
                      ),
                      onPressed: () {
                        setDialogState(() {
                          localIsRecording = !localIsRecording;
                        });
                        if (!localIsRecording) {
                          Navigator.of(context).pop();
                          _showPrescriptionForm(isPrefilled: true);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
