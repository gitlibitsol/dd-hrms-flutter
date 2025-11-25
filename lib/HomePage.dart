import 'package:dd_hrms/MarkAttendancePage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginPage.dart';
import 'Model/MainPageModel.dart';
import 'QrCodeScanner.dart';
import 'network/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final List<MainPageModel> services = [
    MainPageModel(name: "Mark Your Attendance", image: 'assets/images/logo.jpg'),
    MainPageModel(name: "Mark WFH/OD Attendance", image: 'assets/images/logo.jpg'),
  ];

  bool isLoading = true;
  String empInTime = 'N/A';
  String empOutTime = 'N/A';
  String userName = 'User';
  String empImageIn = '';
  String empImageOut = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadAttendance();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserName = prefs.getString('name');
    if (!mounted) return;

    setState(() => userName = savedUserName ?? 'User');
  }

  Future<void> _loadAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('userid');

    if (savedUserId == null || savedUserId.isEmpty) {
      _setAttendanceError('Invalid User ID');
      return;
    }

    try {
      final data = await _apiService.fetchAttendance(savedUserId);
      if (!mounted) return;
      _handleResponseData(data);
    } catch (e) {
      _setAttendanceError('Could not fetch attendance. Please try again.');
    }
  }

  void _handleResponseData(Map<String, dynamic> data) {
    if (data['Status_Code'] == "200") {
      final attendanceList = data['DailyMobileAtt'] as List<dynamic>;
      if (attendanceList.isNotEmpty) {
        String? firstInTime;
        String? firstInImage;
        String? lastOutTime;
        String? lastOutImage;

        for (var attendance in attendanceList) {
          final punchType = attendance['PunchType']?.toString() ?? '';
          if (punchType.toLowerCase() == "in" && firstInTime == null) {
            firstInTime = attendance['TimeOfThumb'] ?? 'N/A';
            firstInImage = attendance['Image'] ?? '';
          } else if (punchType.toLowerCase() == "out") {
            lastOutTime = attendance['TimeOfThumb'] ?? 'N/A';
            lastOutImage = attendance['Image'] ?? '';
          }
        }
        setState(() {
          empInTime = firstInTime ?? 'N/A';
          empImageIn = firstInImage ?? '';
          empOutTime = lastOutTime ?? 'N/A';
          empImageOut = lastOutImage ?? '';
          isLoading = false;
        });
      } else {
        _setAttendanceError('No Records Found');
      }
    } else {
      _setAttendanceError(data['Message'] ?? 'Unexpected error');
    }
  }

  void _setAttendanceError(String message) {
    if (!mounted) return;
    setState(() {
      empInTime = 'N/A';
      empOutTime = 'N/A';
      isLoading = false;
    });
    _showSnackBar(message, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
              );
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildAttendanceRow(),
                _buildServicesGrid(),
              ],
            ),
            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/background.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5), BlendMode.darken),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Welcome to DD-HRMS',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: _showLogoutDialog,
                  child: const Icon(Icons.logout, color: Colors.redAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text('Hello, $userName!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/images/logo.jpg',
              fit: BoxFit.contain, // ✅ पूरी image दिखाई देगी, कटेगी नहीं
            ),
          ),

          const SizedBox(height: 10),
          const Text('DD-HRMS',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAttendanceRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildAttendanceTile(Icons.login, "In Time", empInTime),
            Container(height: 50, width: 1, color: Colors.grey.shade300),
            _buildAttendanceTile(Icons.logout, "Out Time", empOutTime),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTile(IconData icon,String label,String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(time,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildServicesGrid() {
    return Expanded(
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.9,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: services.length,
        itemBuilder: (_, index) => _buildServiceCard(services[index]),
      ),
    );
  }

  Widget _buildServiceCard(MainPageModel service) {
    return InkWell(
      onTap: () {
        if (service.name == "Mark Your Attendance") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => QrCodeScanner()));
        } else if (service.name == "Mark WFH/OD Attendance") {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => MarkAttendancePage()));
        }
      },
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(service.image, width: 60, height: 60),
            const SizedBox(height: 12),
            Text(
              service.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

}
