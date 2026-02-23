// main.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProfileCardApp());
}

class ProfileCardApp extends StatelessWidget {
  const ProfileCardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile Card',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A1628),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  String name = 'Muhammad Nabeel';
  String designation = 'Full Stack Developer';
  String company = 'Tech Innovators Inc.';
  String email = 'nabeelrafique101@gmail.com';
  String phone = '+92 3196537101';
  String location = 'Vehari, Pakistan';
  String bio =
      'Passionate full-stack developer with expertise in mobile and web technologies. '
      'Building scalable solutions that make a difference. Open source contributor and tech community advocate.';
  final String github = 'https://github.com/nabeel-create';
  final String linkedin = 'https://fileuploaddownload12.streamlit.app/';

  List<String> skills = [
    'Flutter',
    'React Native',
    'TypeScript',
    'Node.js',
    'Python',
    'Firebase',
    'AWS',
    'Docker',
  ];

  static const Color navy = Color(0xFF0A1628);
  static const Color darkBlue = Color(0xFF111D33);
  static const Color cardBg = Color(0xFF162033);
  static const Color cardBorder = Color(0xFF1E2D4A);
  static const Color teal = Color(0xFF00D4AA);
  static const Color cyan = Color(0xFF00C6FB);
  static const Color textPrimary = Color(0xFFF0F4F8);
  static const Color textSecondary = Color(0xFF8899AA);
  static const Color textMuted = Color(0xFF5A6B7E);

  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();

  late AnimationController _headerAnimController;
  late AnimationController _statsAnimController;
  late AnimationController _sectionsAnimController;
  late AnimationController _buttonAnimController;

  late Animation<double> _headerFadeAnim;
  late Animation<Offset> _headerSlideAnim;
  late List<Animation<double>> _statsFadeAnims;
  late List<Animation<Offset>> _statsSlideAnims;
  late Animation<double> _sectionsFadeAnim;
  late Animation<Offset> _sectionsSlideAnim;
  late Animation<double> _buttonFadeAnim;
  late Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _headerSlideAnim =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _statsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _statsFadeAnims = List.generate(3, (i) {
      return CurvedAnimation(
        parent: _statsAnimController,
        curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeOut),
      );
    });
    _statsSlideAnims = List.generate(3, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 0.4),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _statsAnimController,
          curve: Interval(i * 0.2, 0.6 + i * 0.2, curve: Curves.easeOutCubic),
        ),
      );
    });

    _sectionsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _sectionsFadeAnim = CurvedAnimation(
      parent: _sectionsAnimController,
      curve: Curves.easeOut,
    );
    _sectionsSlideAnim =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _sectionsAnimController,
            curve: Curves.easeOutCubic,
          ),
        );

    _buttonAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _buttonFadeAnim = CurvedAnimation(
      parent: _buttonAnimController,
      curve: Curves.easeOut,
    );
    _buttonScaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.elasticOut),
    );

    _loadProfileImage();
    _loadAdminData();
    _startAnimations();
  }

  Future<void> _saveAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("name", name);
      await prefs.setString("designation", designation);
      await prefs.setString("company", company);
      await prefs.setString("email", email);
      await prefs.setString("phone", phone);
      await prefs.setString("location", location);
      await prefs.setString("bio", bio);
      await prefs.setStringList("skills", skills);
    } catch (e) {
      debugPrint('Error saving admin data: $e');
    }
  }

  Future<void> _loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        name = prefs.getString("name") ?? name;
        designation = prefs.getString("designation") ?? designation;
        company = prefs.getString("company") ?? company;
        email = prefs.getString("email") ?? email;
        phone = prefs.getString("phone") ?? phone;
        location = prefs.getString("location") ?? location;
        bio = prefs.getString("bio") ?? bio;
        skills = prefs.getStringList("skills") ?? skills;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
    }
  }

  void _openAdminPanel() async {
    TextEditingController nameController = TextEditingController(text: name);
    TextEditingController roleController = TextEditingController(
      text: designation,
    );
    TextEditingController companyController = TextEditingController(
      text: company,
    );
    TextEditingController emailController = TextEditingController(text: email);
    TextEditingController phoneController = TextEditingController(text: phone);
    TextEditingController locationController = TextEditingController(
      text: location,
    );
    TextEditingController bioController = TextEditingController(text: bio);
    TextEditingController skillsController = TextEditingController(
      text: skills.join(","),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text("Admin Panel", style: TextStyle(fontSize: 22)),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name"),
                ),
                TextField(
                  controller: roleController,
                  decoration: const InputDecoration(labelText: "Role"),
                ),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: "Company"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: "Phone"),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: "Location"),
                ),
                TextField(
                  controller: bioController,
                  decoration: const InputDecoration(labelText: "Bio"),
                  maxLines: 3,
                ),
                TextField(
                  controller: skillsController,
                  decoration: const InputDecoration(
                    labelText: "Skills (comma separated)",
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            name = nameController.text;
                            designation = roleController.text;
                            company = companyController.text;
                            email = emailController.text;
                            phone = phoneController.text;
                            location = locationController.text;
                            bio = bioController.text;
                            skills = skillsController.text
                                .split(',')
                                .map((s) => s.trim())
                                .where((s) => s.isNotEmpty)
                                .toList();
                          });

                          await _saveAdminData();
                          Navigator.pop(context);
                        },
                        child: const Text("SAVE"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _pickImage();
                      },
                      child: const Text("Change Image"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _headerAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _statsAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _sectionsAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _buttonAnimController.forward();
  }

  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (kIsWeb) {
        // Web platform: load from base64 in SharedPreferences
        final imageBase64 = prefs.getString('profile_image_base64');
        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final bytes = base64Decode(imageBase64);
            setState(() => _profileImageBytes = bytes);
            debugPrint('Profile image restored from web storage');
          } catch (e) {
            debugPrint('Error decoding image base64: $e');
          }
        }
      } else {
        // Native platforms: use file system
        final imagePath = prefs.getString('profile_image_path');
        if (imagePath != null && await File(imagePath).exists()) {
          final bytes = await File(imagePath).readAsBytes();
          setState(() => _profileImageBytes = bytes);
        }
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
    }
  }

  Future<void> _saveProfileImage(Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        // Web platform: store as base64 in SharedPreferences
        try {
          final imageBase64 = base64Encode(bytes);
          await prefs.setString('profile_image_base64', imageBase64);
          debugPrint(
            'Profile image saved to web storage (${bytes.length} bytes)',
          );
        } catch (e) {
          debugPrint('Error encoding image to base64: $e');
        }
        // Update UI
        setState(() => _profileImageBytes = bytes);
      } else {
        // Native platforms: save to file system
        try {
          final dir = await getApplicationDocumentsDirectory();
          final imagePath = '${dir.path}/profile_image.jpg';
          final file = File(imagePath);
          await file.writeAsBytes(bytes);
          await prefs.setString('profile_image_path', imagePath);
          setState(() => _profileImageBytes = bytes);
        } catch (e) {
          debugPrint(
            'Error with file storage: $e, falling back to memory storage',
          );
          // Fallback: just keep in memory if file system fails
          setState(() => _profileImageBytes = bytes);
        }
      }
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      // Still update the UI even if persistent storage fails
      setState(() => _profileImageBytes = bytes);
    }
  }

  Future<void> _deleteProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (kIsWeb) {
        // Web platform: remove from storage
        await prefs.remove('profile_image_base64');
        debugPrint('Profile image removed from web storage');
      } else {
        // Native platforms: remove file
        final imagePath = prefs.getString('profile_image_path');
        if (imagePath != null) {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
          }
          await prefs.remove('profile_image_path');
        }
      }
    } catch (e) {
      debugPrint('Error deleting profile image: $e');
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _statsAnimController.dispose();
    _sectionsAnimController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: teal.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.camera_alt, color: teal, size: 22),
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                    maxWidth: 800,
                    maxHeight: 800,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    await _saveProfileImage(bytes);
                    setState(() => _profileImageBytes = bytes);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: cyan.withOpacity(0.12),
                  ),
                  child: const Icon(Icons.photo_library, color: cyan, size: 22),
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                    maxWidth: 800,
                    maxHeight: 800,
                  );
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    await _saveProfileImage(bytes);
                    setState(() => _profileImageBytes = bytes);
                  }
                },
              ),
              if (_profileImageBytes != null)
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.red.withOpacity(0.12),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteProfileImage();
                    setState(() => _profileImageBytes = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: teal, size: 20),
            const SizedBox(width: 10),
            Text(
              '$label copied to clipboard',
              style: const TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 40,
          ),
          child: Column(
            children: [
              SlideTransition(
                position: _headerSlideAnim,
                child: FadeTransition(
                  opacity: _headerFadeAnim,
                  child: _buildHeader(),
                ),
              ),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 24),
              SlideTransition(
                position: _sectionsSlideAnim,
                child: FadeTransition(
                  opacity: _sectionsFadeAnim,
                  child: Column(
                    children: [
                      _buildAboutSection(),
                      const SizedBox(height: 24),
                      _buildContactSection(),
                      const SizedBox(height: 24),
                      _buildTechStackSection(),
                      const SizedBox(height: 24),
                      _buildConnectSection(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _buttonFadeAnim,
                child: ScaleTransition(
                  scale: _buttonScaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [_buildGetInTouchButton(), _buildShareButton()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2444), Color(0xFF0A1628), Color(0xFF0D1B2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cyan.withOpacity(0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            child: Column(
              children: [
                _buildAvatar(),
                const SizedBox(height: 20),
                _buildNameSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _pickImage,
      onLongPress: () {
        _openAdminPanel();
      },
      child: Stack(
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [teal, cyan]),
            ),
            child: Center(
              child: Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: navy,
                ),
                child: Center(
                  child: Container(
                    width: 98,
                    height: 98,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A2A44),
                    ),
                    child: ClipOval(
                      child: _profileImageBytes != null
                          ? Image.memory(
                              _profileImageBytes!,
                              width: 98,
                              height: 98,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(color: darkBlue, width: 3),
              ),
            ),
          ),
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [teal, cyan]),
                border: Border.all(color: navy, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: [teal, cyan]),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.code, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                designation,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_outline, size: 13, color: textMuted),
            const SizedBox(width: 6),
            Text(
              company,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on_outlined, size: 14, color: textMuted),
            const SizedBox(width: 4),
            Text(
              location,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: SlideTransition(
            position: _statsSlideAnims[0],
            child: FadeTransition(
              opacity: _statsFadeAnims[0],
              child: _buildStatCard('25+', 'Projects', Icons.code),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SlideTransition(
            position: _statsSlideAnims[1],
            child: FadeTransition(
              opacity: _statsFadeAnims[1],
              child: _buildStatCard('3+ Yrs', 'Experience', Icons.access_time),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SlideTransition(
            position: _statsSlideAnims[2],
            child: FadeTransition(
              opacity: _statsFadeAnims[2],
              child: _buildStatCard('15+', 'Clients', Icons.people_outline),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cyan.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cyan.withOpacity(0.08),
            ),
            child: Icon(icon, size: 18, color: cyan),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: teal),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('About', Icons.person_outline),
        const SizedBox(height: 14),
        Text(
          bio,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Contact', Icons.phone_outlined),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            children: [
              _buildContactRow(
                Icons.email_outlined,
                'Email',
                email,
                onTap: () => _copyToClipboard(email, 'Email'),
              ),
              Divider(color: cardBorder, height: 1, indent: 64),
              _buildContactRow(
                Icons.phone_outlined,
                'Phone',
                phone,
                onTap: () => _copyToClipboard(phone, 'Phone'),
              ),
              Divider(color: cardBorder, height: 1, indent: 64),
              _buildContactRow(
                Icons.location_on_outlined,
                'Location',
                location,
                onTap: () => _copyToClipboard(location, 'Location'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: teal.withOpacity(0.12),
              ),
              child: Icon(icon, size: 16, color: teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTechStackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Tech Stack', Icons.code),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills.map((skill) => _buildSkillBadge(skill)).toList(),
        ),
      ],
    );
  }

  Widget _buildSkillBadge(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: teal.withOpacity(0.25)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: teal,
        ),
      ),
    );
  }

  Widget _buildConnectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Connect', Icons.language),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              Icons.code,
              Colors.white,
              onTap: () => _launchUrl(github),
            ),
            const SizedBox(width: 14),
            _buildSocialButton(
              Icons.work,
              const Color(0xFF0A66C2),
              onTap: () => _launchUrl(linkedin),
            ),
            const SizedBox(width: 14),
            _buildSocialButton(
              Icons.language,
              cyan,
              onTap: () => _launchUrl(github),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }

  Widget _buildGetInTouchButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [teal, cyan]),
        boxShadow: [
          BoxShadow(
            color: teal.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openWhatsApp(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 18, color: navy),
                SizedBox(width: 10),
                Text(
                  'Get In Touch',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    // Target number provided by user (local format). We'll convert to international.
    String rawNumber = '03196537101';
    String phone;
    if (rawNumber.startsWith('+')) {
      phone = rawNumber.substring(1);
    } else if (rawNumber.startsWith('0')) {
      // Assuming Pakistan (+92) for numbers starting with 0
      phone = '92' + rawNumber.substring(1);
    } else {
      phone = rawNumber;
    }

    final message = 'Hello, I would like to get in touch.';
    final encoded = Uri.encodeComponent(message);
    final url = 'https://wa.me/$phone?text=$encoded';

    await _launchUrl(url);
  }

  Future<void> _shareProfile() async {
    final text =
        '''
👋 Hello, check my developer profile

Name: $name
Role: $designation

📧 Email:
$email

💻 GitHub:
$github

📱 Contact:
$phone
''';

    await Share.share(text);
  }

  Widget _buildShareButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: _shareProfile,
        icon: const Icon(Icons.share),
        label: const Text("Share Profile"),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
