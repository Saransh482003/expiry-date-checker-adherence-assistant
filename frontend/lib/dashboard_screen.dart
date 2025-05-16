// filepath: e:\expiry-date-checker-adherence-assistant\frontend\lib\success_screen.dart
import 'package:flutter/material.dart';
import 'package:frontend/services/noti_serve.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme_constants.dart';
import 'constants.dart';
import 'add_prescription_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final String password;
  
  const DashboardScreen({
    Key? key,
    required this.username,
    required this.password,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _sideEffectsController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _sideEffectsController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }



  Future<void> _fetchUserData() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': widget.username,
          'password': widget.password,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isLoading = false;
        });
        print(userData);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${response.body}')),
        );
        setState(() => isLoading = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),        backgroundColor: ThemeConstants.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/expiry-check');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Enhanced Profile Section
                  Container(
                    decoration: const BoxDecoration(
                      color: ThemeConstants.primaryColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Decorative circles
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
                        // Existing content
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circle
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                // Profile picture container
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person,
                                      size: 60,
                                      color: ThemeConstants.primaryColor,
                                    ),
                                  ),
                                ),
                                // Edit button
                                Positioned(
                                  bottom: 0,
                                  right: MediaQuery.of(context).size.width * 0.28,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ThemeConstants.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: ThemeConstants.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // User info with icons
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                children: [
                                  Text(
                                    userData?['name'] ?? widget.username,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.email_outlined,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        userData?['email'] ?? 'Loading...',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Quick stats
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildQuickStat(
                                          'Prescriptions',
                                          '${(userData?['prescriptions'] as List?)?.length ?? 0}',
                                          Icons.medication_outlined,
                                        ),
                                        _buildQuickStat(
                                          'Completed',
                                          '80%',
                                          Icons.check_circle_outline,
                                        ),
                                        _buildQuickStat(
                                          'Upcoming',
                                          '3',
                                          Icons.upcoming_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // User Information Cards
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.phone,
                          title: 'Phone',
                          value: userData?['phone'] ?? 'Not provided',
                        ),
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Date of Birth',
                          value: userData?['dob'] ?? 'Not provided',
                        ),
                        _buildInfoCard(
                          icon: Icons.wc,
                          title: 'Gender',
                          value: userData?['gender'] ?? 'Not provided',
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Prescription Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (userData?['prescriptions'] != null)
                          ...List<Widget>.from(
                            (userData!['prescriptions'] as List).map(                              (prescription) => _buildPrescriptionCard(
                                medicineName: prescription['medicine_name'],
                                presId: prescription['pres_id'],
                                recommendedDosage: prescription['recommended_dosage'],
                                sideEffects: prescription['side_effects'],
                                frequency: prescription['frequency'],
                                expiryDate: prescription['expiry_date'],
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Text(
                              'No prescriptions found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPrescriptionScreen(
                      username: widget.username,
                      password: widget.password,
                      userId: userData?['user_id'] ?? '',
                    ),
                  ),
                );
          if (result == true) {
            _fetchUserData(); // Refresh the prescriptions list
          }
        },
        backgroundColor: ThemeConstants.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Prescription',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: ThemeConstants.primaryColor, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPrescriptionCard({
    required String medicineName,
    required String presId,
    required String recommendedDosage,
    required String sideEffects,
    required int frequency,
    required String expiryDate,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medication,
                    color: ThemeConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medicineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: $presId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThemeConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$frequency times/day',
                    style: const TextStyle(
                      color: ThemeConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPrescriptionDetail(
              icon: Icons.schedule,
              title: 'Dosage',
              value: recommendedDosage,
            ),
            const SizedBox(height: 8),            _buildPrescriptionDetail(
              icon: Icons.warning_amber_rounded,
              title: 'Side Effects',
              value: sideEffects,
            ),
            const SizedBox(height: 8),
            _buildPrescriptionDetail(
              icon: Icons.event_available,
              title: 'Expiry Date',
              value: expiryDate,
            ),
            const SizedBox(height: 16),
            // New Button
            SizedBox(
              width: double.infinity,              child: ElevatedButton(
                onPressed: () async {                  TimeOfDay? selectedTime = await showDialog<TimeOfDay>(
  context: context,
  builder: (BuildContext context) {
    int selectedHour = 14;  // Default to 2
    bool isPM = true;      // Default to PM
    int selectedMinute = 0;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Set Reminder Time',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ThemeConstants.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Container(                    decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeConstants.primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hour',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            width: 80,
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              useMagnifier: true,
                              magnification: 1.3,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedHour = index + 1;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 12,
                                builder: (context, index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: selectedHour == index + 1 
                                          ? ThemeConstants.primaryColor.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}'.padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: selectedHour == index + 1 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: selectedHour == index + 1
                                              ? ThemeConstants.primaryColor
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 100,
                        width: 1,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Minute',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 150,
                            width: 80,
                            child: ListWheelScrollView.useDelegate(
                              itemExtent: 50,
                              perspective: 0.005,
                              diameterRatio: 1.2,
                              physics: const FixedExtentScrollPhysics(),
                              useMagnifier: true,
                              magnification: 1.3,
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  selectedMinute = index * 5;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 12,
                                builder: (context, index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: selectedMinute == index * 5 
                                          ? ThemeConstants.primaryColor.withOpacity(0.1)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index * 5}'.padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: selectedMinute == index * 5 
                                              ? FontWeight.bold 
                                              : FontWeight.normal,
                                          color: selectedMinute == index * 5
                                              ? ThemeConstants.primaryColor
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPeriodButton(
                        label: 'AM',
                        isSelected: !isPM,
                        onTap: () => setState(() => isPM = false),
                      ),
                      const SizedBox(width: 8),
                      _buildPeriodButton(
                        label: 'PM',
                        isSelected: isPM,
                        onTap: () => setState(() => isPM = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        final hour = isPM ? 
                          (selectedHour == 12 ? 12 : selectedHour + 12) : 
                          (selectedHour == 12 ? 0 : selectedHour);
                        Navigator.pop(
                          context,
                          TimeOfDay(hour: hour, minute: selectedMinute),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Set Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  },
);

                  if (selectedTime != null && mounted) {
                    await NotiService().scheduleNotification(
                      id: 0,
                      title: 'Daily Medicine Reminder',
                      body: 'Time to take $medicineName',
                      hour: selectedTime.hour,
                      minute: selectedTime.minute,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reminder set for ${selectedTime.format(context)}',
                        ),
                        backgroundColor: ThemeConstants.primaryColor,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: ThemeConstants.primaryColor,
                ),
                child: const Text(
                  'Set Reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildPrescriptionDetail({
    required IconData icon,
    required String title,
    required String value,
  }) {
    String displayValue = value;
    String daysRemaining = '';
    Color? textColor = Colors.grey[600];

    if (title == 'Expiry Date' && value.isNotEmpty) {
      try {
        final parts = value.split('-');
        if (parts.length == 3) {
          final expiryDate = DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
          
          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          displayValue = '${parts[0]} ${months[int.parse(parts[1]) - 1]} ${parts[2]}';
          
          final daysLeft = expiryDate.difference(DateTime(2025, 5, 17)).inDays;
          if (daysLeft < 0) {
            daysRemaining = 'Expired';
            textColor = Colors.red;
          } else {
            daysRemaining = '$daysLeft days remaining';
            if (daysLeft < 30) {
              textColor = Colors.orange;
            }
          }
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                displayValue,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: title == 'Expiry Date' ? FontWeight.w500 : null,
                ),
              ),
              if (daysRemaining.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  daysRemaining,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: ThemeConstants.primaryColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? ThemeConstants.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : ThemeConstants.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

}