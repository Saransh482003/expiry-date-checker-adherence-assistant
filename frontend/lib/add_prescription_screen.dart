import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'theme_constants.dart';
import 'constants.dart';
import 'package:record/record.dart';
import 'expiry-date-check.dart';

class AddPrescriptionScreen extends StatefulWidget {
  final String username;
  final String password;
  final String userId;

  const AddPrescriptionScreen({
    Key? key,
    required this.username,
    required this.password,
    required this.userId,
  }) : super(key: key);

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _sideEffectsController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final AudioRecorder audioRecorder = AudioRecorder();

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _sideEffectsController.dispose();
    _frequencyController.dispose();
    _expiryDateController.dispose();
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
          'user_id': widget.userId,
          'med_name': _medicineNameController.text,
          'recommended_dosage': _dosageController.text,
          'side_effects': _sideEffectsController.text,
          'frequency': int.parse(_frequencyController.text),
          'expiry_date': _expiryDateController.text,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription added successfully'),
              backgroundColor: ThemeConstants.primaryColor,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to add prescription: ${response.body}')),
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

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Lottie.asset(
                    'assets/scanning.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hearing your whispers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
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
      ),
      body: Column(
        children: [
          // Top section with modern design
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
                          child: const Icon(
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
                    subtitle: 'Take a photo of your prescription',                    onTap: () {
                      // TODO: Implement camera capture
                      _showPrescriptionForm(isPrefilled: true, similarMatches: []);
                    },
                  ),
                  _buildOptionButton(
                    icon: Icons.mic,
                    title: 'Voice Input',
                    subtitle: 'Dictate your prescription details',
                    onTap: _showRecordingModal,
                  ),
                  _buildOptionButton(
                    icon: Icons.edit,
                    title: 'Manual Entry',
                    subtitle: 'Type in prescription details',
                    onTap: () => _showPrescriptionForm(isPrefilled: false, similarMatches: []),
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

  void _showPrescriptionForm({required bool isPrefilled, List<String>? similarMatches}) {
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
                      if (isPrefilled && similarMatches != null && similarMatches.isNotEmpty) ...[
                        const Text(
                          'Similar Medicine Names',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ThemeConstants.primaryColor,
                                  side: const BorderSide(color: ThemeConstants.primaryColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),  // Keep current name
                                child: const Text('None'),
                              ),
                              const SizedBox(width: 8),
                              ...similarMatches.map((name) =>
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: OutlinedButton(                                    onPressed: () async {
                                      setState(() {
                                        _medicineNameController.text = name;
                                      });
                                      await _getMedicineDetails(name);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: ThemeConstants.primaryColor,
                                      side: const BorderSide(color: ThemeConstants.primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(name),
                                  ),
                                ),
                              ).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _expiryDateController,
                        label: 'Expiry Date',
                        icon: Icons.calendar_today,
                        suffix: IconButton(
                          icon: const Icon(Icons.document_scanner),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ExpiryDateCheck(),
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _expiryDateController.text = result;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          _addPrescription();
                          Navigator.pop(
                              context); // Close the bottom sheet first
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
                      const SizedBox(
                          height: 16), // Add padding for bottom safe area
                      SizedBox(
                          height: MediaQuery.of(context)
                              .viewInsets
                              .bottom), // Handle keyboard
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
    Widget? suffix,
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
          suffixIcon: suffix,
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
            borderSide: const BorderSide(color: ThemeConstants.primaryColor),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAudioUpload(File audioFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/transcribe'));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
        ),
      );
      var response = await request.send();
      await audioFile.delete();
      Navigator.of(context).pop(); // Close loading dialog
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        _handleVoiceApiResponse(responseData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send recording')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading recording')),
      );
    }
  }

  void _showRecordingModal() {
    bool localIsRecording = false;
    String? recordingPath;
    int remainingSeconds = 30;

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
                  const SizedBox(height: 16),
                  if (!localIsRecording)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'You will have 30 seconds to speak your prescription details. Recording starts when you tap the mic.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  if (localIsRecording)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '$remainingSeconds s',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
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
                      onPressed: () async {
                        if (!localIsRecording) {
                          if (await audioRecorder.hasPermission()) {
                            final Directory appDocumentDir = await getApplicationDocumentsDirectory();
                            final String filePath = '${appDocumentDir.path}/prescription_recording.wav';
                            await audioRecorder.start(const RecordConfig(), path: filePath);
                            setDialogState(() {
                              localIsRecording = true;
                              recordingPath = filePath;
                              remainingSeconds = 30;
                            });

                            // Start countdown timer
                            Timer.periodic(const Duration(seconds: 1), (timer) {
                              if (!localIsRecording || remainingSeconds <= 0) {
                                timer.cancel();
                                return;
                              }
                              setDialogState(() {
                                remainingSeconds--;
                              });
                            });

                            // Set 30-second limit
                            Future.delayed(const Duration(seconds: 30), () async {
                              if (localIsRecording) {
                                String? audioPath = await audioRecorder.stop();
                                if (audioPath != null) {
                                  final File audioFile = File(audioPath);
                                  setDialogState(() {
                                    localIsRecording = false;
                                    recordingPath = null;
                                  });
                                  Navigator.of(context).pop();
                                  _showProcessingDialog(); // Show loading animation
                                  await _handleAudioUpload(audioFile);
                                }
                              }
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Microphone permission denied')),
                            );
                          }
                        } else {
                          String? audioPath = await audioRecorder.stop();
                          if (audioPath != null) {
                            final File audioFile = File(audioPath);
                            setDialogState(() {
                              localIsRecording = !localIsRecording;
                              recordingPath = null;
                            });
                            Navigator.of(context).pop();
                            _showProcessingDialog(); // Show loading animation
                            await _handleAudioUpload(audioFile);
                          }
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
  void _handleVoiceApiResponse(String responseData) {
    var jsonResponse = jsonDecode(responseData);
    print('Recording sent and deleted successfully. Response: $responseData');
    
    // Extract similar matches from response
    List<String> similarMatches = (jsonResponse['similar-matches'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    
    // Pre-fill the form fields
    _medicineNameController.text = jsonResponse['medicine_name'] ?? '';
    _frequencyController.text = (jsonResponse['frequency']?.toString() ?? '');
    _dosageController.text = jsonResponse['recommended_dosage'] ?? '';
    _sideEffectsController.text = jsonResponse['side_effects'] ?? '';

    // Show the form with similar matches
    _showPrescriptionForm(isPrefilled: true, similarMatches: similarMatches);
  }

  Future<void> _getMedicineDetails(String medicineName) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-medicine?med_name=$medicineName'),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        setState(() {
          _dosageController.text = jsonResponse['recommended_dosage'] ?? '';
          _sideEffectsController.text = jsonResponse['side_effects'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error fetching medicine details')),
      );
    }
  }
}
