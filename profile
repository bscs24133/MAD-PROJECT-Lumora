import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(LumoraAppWithAuth());
}

// ===============================================
// AUTHENTICATION WRAPPER & AUTH SCREENS
// ===============================================

class LumoraAppWithAuth extends StatefulWidget {
  @override
  State<LumoraAppWithAuth> createState() => _LumoraAppWithAuthState();
}

class _LumoraAppWithAuthState extends State<LumoraAppWithAuth> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  void checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool("loggedIn") ?? false;
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: isLoading
          ? Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      )
          : isLoggedIn
          ? const HomeScreen()
          : AuthIntroScreen(),
    );
  }
}

/// ---------------------------
/// USER PROFILE SCREEN
/// ---------------------------
class UserProfileScreen extends StatefulWidget {
  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  String? userName;
  String? userEmail;
  String? profileImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString("activeEmail");
    List<String> saved = prefs.getStringList("users") ?? [];

    for (var u in saved) {
      Map user = jsonDecode(u);
      if (user["email"] == email) {
        setState(() {
          userName = user["name"];
          userEmail = user["email"];
          profileImagePath = user["profileImage"];
        });
        break;
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _updateProfileImage(image.path);
    }
  }

  Future<void> _updateProfileImage(String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString("activeEmail");
    List<String> saved = prefs.getStringList("users") ?? [];

    List<String> updatedUsers = [];
    for (var u in saved) {
      Map user = jsonDecode(u);
      if (user["email"] == email) {
        user["profileImage"] = imagePath;
      }
      updatedUsers.add(jsonEncode(user));
    }

    await prefs.setStringList("users", updatedUsers);
    setState(() {
      profileImagePath = imagePath;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile image updated!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _updateUserName(String newName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString("activeEmail");
    List<String> saved = prefs.getStringList("users") ?? [];

    List<String> updatedUsers = [];
    for (var u in saved) {
      Map user = jsonDecode(u);
      if (user["email"] == email) {
        user["name"] = newName;
      }
      updatedUsers.add(jsonEncode(user));
    }

    await prefs.setStringList("users", updatedUsers);
    setState(() {
      userName = newName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Name updated!'), duration: Duration(seconds: 2)),
    );
  }

  void _showEditNameDialog() {
    TextEditingController nameController = TextEditingController(text: userName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF0F1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                _updateUserName(nameController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
            ),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color(0xFF0F1A2E),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Profile', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Image Section
            Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                    ),
                  ),
                  child: profileImagePath != null
                      ? ClipOval(
                    child: Image.file(
                      File(profileImagePath!),
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // User Info Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F1A2E), Color(0xFF1C2A47)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF60A5FA), size: 20),
                        onPressed: _showEditNameDialog,
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildInfoItem('Name', userName ?? 'Not set'),
                  _buildInfoItem('Email', userEmail ?? 'Not set'),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Stats Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0F1A2E), Color(0xFF1C2A47)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Stats',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Colors\nDetected', '0'),
                      _buildStatItem('Vision\nTests', '0'),
                      _buildStatItem('Account\nAge', 'New'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Divider(color: Colors.white12),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Color(0xFF60A5FA),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------
/// USER INFO LIST (Long Press Delete)
/// ---------------------------
class UserInfoListScreen extends StatefulWidget {
  @override
  State<UserInfoListScreen> createState() => _UserInfoListScreenState();
}

class _UserInfoListScreenState extends State<UserInfoListScreen> {
  List<Map> users = [];
  String? currentUserEmail;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("users") ?? [];
    currentUserEmail = prefs.getString("activeEmail");
    users = saved.map((e) => jsonDecode(e) as Map).toList();
    setState(() {});
  }

  Future<void> deleteUser(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("users") ?? [];

    saved.removeAt(index);
    prefs.setStringList("users", saved);

    // If deleted user is the current user, log out
    if (users[index]["email"] == currentUserEmail) {
      prefs.setBool("loggedIn", false);
      prefs.remove("activeEmail");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AuthIntroScreen()),
            (route) => false,
      );
    } else {
      loadUsers();
    }
  }

  void showDeleteDialog(int index) {
    bool isCurrentUser = users[index]["email"] == currentUserEmail;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text(
              "Delete Account?",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete this account?",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            if (isCurrentUser) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "This is your active account. You'll be logged out.",
                        style: TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          // NO BUTTON
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text("Cancel", style: TextStyle(color: Colors.white, fontSize: 16)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          // YES BUTTON
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text("Delete", style: TextStyle(color: Colors.white, fontSize: 16)),
            onPressed: () {
              deleteUser(index);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A2E),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.people, color: Color(0xFF60A5FA)),
            SizedBox(width: 12),
            Text("User Accounts", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: users.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.white24),
            SizedBox(height: 20),
            Text(
              "No accounts found",
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              "Create an account to get started",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, i) {
          bool isCurrentUser = users[i]["email"] == currentUserEmail;

          return GestureDetector(
            onLongPress: () => showDeleteDialog(i),
            onTap: isCurrentUser ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => UserProfileScreen()),
              );
            } : null,
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCurrentUser
                      ? [Color(0xFF1E3A8A), Color(0xFF1E40AF)]
                      : [Color(0xFF0F1A2E), Color(0xFF1C2A47)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrentUser
                      ? Color(0xFF3B82F6).withOpacity(0.5)
                      : Colors.white12,
                  width: 2,
                ),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCurrentUser
                          ? [Color(0xFF60A5FA), Color(0xFF3B82F6)]
                          : [Color(0xFF374151), Color(0xFF1F2937)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: users[i]["profileImage"] != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(users[i]["profileImage"]),
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  )
                      : Icon(
                    isCurrentUser ? Icons.person : Icons.person_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        users[i]["name"],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Active",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    users[i]["email"],
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                trailing: Icon(
                  isCurrentUser ? Icons.arrow_forward_ios : Icons.more_vert,
                  color: Colors.white54,
                  size: isCurrentUser ? 16 : 24,
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF0F1A2E),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "💡 Tap your active account to edit profile",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                "💡 Long press any account to delete",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// AUTH INTRO SCREEN
// ===============================================

class AuthIntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eye Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(Icons.remove_red_eye, size: 60, color: Colors.white),
              ),
              SizedBox(height: 50),

              // Lumora Title
              Text(
                "LUMORA",
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 10),

              // Subtitle
              Container(
                width: 150,
                height: 2,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Color(0xFF3B82F6), Colors.transparent],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Discover the colour around you",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 80),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AuthWelcomeScreen()),
                      );
                    },
                    child: Text(
                      "Get Started",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// AUTH WELCOME SCREEN
// ===============================================

class AuthWelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(Icons.remove_red_eye, size: 50, color: Colors.white),
                ),
                SizedBox(height: 40),

                Text(
                  "Welcome to Lumora",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  "Sign in to save your colour discoveries\nand personalize your experience",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 60),

                // Log In Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AuthLoginScreen()),
                      );
                    },
                    child: Text(
                      "Log In",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white54, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AuthSignUpScreen()),
                      );
                    },
                    child: Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Skip Button
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: Text(
                    "Skip for now",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================
// LOGIN SCREEN
// ===============================================

class AuthLoginScreen extends StatelessWidget {
  final email = TextEditingController();
  final pass = TextEditingController();

  Future<bool> loginUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("users") ?? [];

    for (var u in saved) {
      Map user = jsonDecode(u);
      if (user["email"] == email.text.trim() &&
          user["password"] == pass.text.trim()) {
        prefs.setBool("loggedIn", true);
        prefs.setString("activeEmail", user["email"]);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Log In", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              authInputField("Email", email),
              SizedBox(height: 20),
              authInputField("Password", pass, obscure: true),
              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Log In",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    bool ok = await loginUser();
                    if (ok) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invalid credentials"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// SIGN UP SCREEN
// ===============================================

class AuthSignUpScreen extends StatelessWidget {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();

  Future<void> saveNewUser(String name, String email, String pass) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("users") ?? [];

    Map<String, dynamic> newUser = {
      "name": name,
      "email": email,
      "password": pass,
      "profileImage": null, // Initialize with no profile image
    };

    saved.add(jsonEncode(newUser));
    prefs.setStringList("users", saved);

    prefs.setBool("loggedIn", true);
    prefs.setString("activeEmail", email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Sign Up", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              authInputField("Full Name", name),
              SizedBox(height: 20),
              authInputField("Email", email),
              SizedBox(height: 20),
              authInputField("Password", pass, obscure: true),
              SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Create Account",
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    await saveNewUser(
                      name.text.trim(),
                      email.text.trim(),
                      pass.text.trim(),
                    );

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===============================================
// AUTH INPUT FIELD HELPER
// ===============================================

Widget authInputField(String label, TextEditingController c, {bool obscure = false}) {
  return TextField(
    controller: c,
    obscureText: obscure,
    style: TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
      ),
      filled: true,
      fillColor: Color(0xFF1C1C1E),
    ),
  );
}

// ===============================================
// HOME SCREEN (Updated with Profile Access)
// ===============================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F1A2E),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A1128), Color(0xFF0F1A2E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Lumora",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Color Detection Pro",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.white70),
              title: const Text('History', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology, color: Colors.white70),
              title: const Text('Color Vision Test', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ColorVisionTest()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white70),
              title: const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen()));
              },
            ),
            const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white70),
              title: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.setBool("loggedIn", false);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => AuthIntroScreen()),
                      (route) => false,
                );
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Lumora v1.0.0\n© 2024 Lumora Technologies',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1F1F1F))),
              ),
              child: Row(
                children: [
                  // Menu Button
                  Builder(
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.4), width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF60A5FA), size: 28),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Logo and Status
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.palette, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lumora',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Ready to Scan',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserInfoListScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Text(
                            'Pro Mode',
                            style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.people, color: Color(0xFF60A5FA), size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF374151), Color(0xFF1F2937)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4B5563)),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content (Keep your existing HomeScreen content here)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Welcome Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 24),
                          SizedBox(width: 8),
                          Text(
                            'WELCOME TO',
                            style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.auto_awesome, color: Color(0xFF60A5FA), size: 24),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'LUMORA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 200,
                        height: 2,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.transparent, Color(0xFF3B82F6), Colors.transparent],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Advanced Color Vision & Detection System',
                        style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Identify colors with precision • Test your vision • Explore palettes',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 60),

                      // Action Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final status = await Permission.camera.request();
                                  if (status.isGranted) {
                                    final cameras = await availableCameras();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CameraScannerPage(cameras: cameras),
                                      ),
                                    );
                                  }
                                },
                                child: _buildActionCard(
                                  icon: Icons.camera_alt,
                                  title: 'Camera',
                                  description: 'Point and scan any object to detect colors instantly in real-time',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () async {
                                  final picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                  if (image != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => UploadResultScreen(imageFile: File(image.path)),
                                      ),
                                    );
                                  }
                                },
                                child: _buildActionCard(
                                  icon: Icons.upload_file,
                                  title: 'Upload',
                                  description: 'Upload images to extract and analyze complete color palettes',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),

                      // Stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat('16M+', 'Colors'),
                          Container(width: 1, height: 48, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 24)),
                          _buildStat('99%', 'Accuracy'),
                          Container(width: 1, height: 48, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 24)),
                          _buildStat('Instant', 'Detection'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A1128), Color(0xFF0F1A2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E40AF).withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

// ===============================================
// REST OF YOUR EXISTING CODE (CameraScannerPage, UploadResultScreen, ColorVisionTest, etc.)
// ===============================================

/// ---------------------------
/// CAMERA SCANNER
/// ---------------------------
class CameraScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScannerPage({required this.cameras, super.key});

  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}

class _CameraScannerPageState extends State<CameraScannerPage> {
  CameraController? controller;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    controller = CameraController(widget.cameras.first, ResolutionPreset.high);
    await controller!.initialize();
    if (!mounted) return;
    setState(() => isReady = true);
  }

  Future<void> _capture() async {
    if (controller == null || !controller!.value.isInitialized) return;
    final file = await controller!.takePicture();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UploadResultScreen(imageFile: File(file.path))),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(controller!)),
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// UPLOAD RESULT SCREEN
/// ---------------------------
class UploadResultScreen extends StatefulWidget {
  final File imageFile;
  const UploadResultScreen({required this.imageFile, super.key});

  @override
  State<UploadResultScreen> createState() => _UploadResultScreenState();
}

class _UploadResultScreenState extends State<UploadResultScreen> {
  Color dominantColor = Colors.white;
  String hex = "", rgb = "", shade = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectColor();
  }

  void _detectColor() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        setState(() => isLoading = false);
        return;
      }

      int rSum = 0, gSum = 0, bSum = 0;
      int count = 0;

      // Sample pixels from the image
      final sampleRate = max(1, image.width ~/ 50);

      for (int y = 0; y < image.height; y += max(1, image.height ~/ 50)) {
        for (int x = 0; x < image.width; x += sampleRate) {
          final pixel = image.getPixel(x, y);

          // Extract RGB values correctly
          rSum += pixel.r.toInt();
          gSum += pixel.g.toInt();
          bSum += pixel.b.toInt();
          count++;
        }
      }

      if (count == 0) {
        setState(() => isLoading = false);
        return;
      }

      final r = rSum ~/ count;
      final g = gSum ~/ count;
      final b = bSum ~/ count;

      setState(() {
        dominantColor = Color.fromARGB(255, r, g, b);
        hex = '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}${g.toRadixString(16).padLeft(2, '0').toUpperCase()}${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
        rgb = 'RGB($r, $g, $b)';
        shade = _getShadeName(r, g, b);
        isLoading = false;
      });
    } catch (e) {
      print('Error detecting color: $e');
      setState(() => isLoading = false);
    }
  }

  String _getShadeName(int r, int g, int b) {
    // Comprehensive color database with 250+ colors
    final Map<String, List<int>> colorDatabase = {
      // ... (keep your existing color database)
      'Red': [255, 0, 0],
      'Green': [0, 128, 0],
      'Blue': [0, 0, 255],
      // ... (rest of your color database)
    };

    // Find the closest color using Euclidean distance
    String closestColorName = 'Unknown';
    double minDistance = double.infinity;

    colorDatabase.forEach((name, rgb) {
      double distance = sqrt(
          pow(r - rgb[0], 2) +
              pow(g - rgb[1], 2) +
              pow(b - rgb[2], 2)
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestColorName = name;
      }
    });

    return closestColorName;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Large Color Display
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: dominantColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: dominantColor.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        shade,
                        style: TextStyle(
                          color: dominantColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hex,
                        style: TextStyle(
                          color: dominantColor.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Color Details Section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Color Details',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Detail Cards
              _buildDetailCard('HEX Code', hex),
              _buildDetailCard('RGB Values', rgb),
              _buildDetailCard('Closest Shade', shade),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white54),
            onPressed: () => _copyToClipboard(value),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// COLOR VISION TEST
/// ---------------------------
class ColorVisionTest extends StatefulWidget {
  const ColorVisionTest({super.key});

  @override
  State<ColorVisionTest> createState() => _ColorVisionTestState();
}

class _ColorVisionTestState extends State<ColorVisionTest> {
  int currentQuestion = 0;
  int correctAnswer = 4;
  List<int> options = [];
  Color bgColor = Colors.grey;
  Color numberColor = Colors.black;
  String colorBlindnessType = '';
  int correctCount = 0;
  List<String> wrongTypes = [];
  final random = Random();

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    correctAnswer = random.nextInt(9) + 1;

    List<Map<String, dynamic>> colorPairs = [
      {
        'bg': const Color(0xFFB2D8B2),
        'num': const Color(0xFFFF3333),
        'type': 'Control (Normal Vision)',
      },
      {
        'bg': const Color(0xFF8B4513),
        'num': const Color(0xFF4CAF50),
        'type': 'Protanopia/Protanomaly',
      },
      {
        'bg': const Color(0xFFBFD200),
        'num': const Color(0xFFFF7043),
        'type': 'Deuteranopia/Deuteranomaly',
      },
      {
        'bg': const Color(0xFF1565C0),
        'num': const Color(0xFFFFEB3B),
        'type': 'Tritanopia/Tritanomaly',
      },
      {
        'bg': const Color(0xFFA8C3A0),
        'num': const Color(0xFFD500F9),
        'type': 'Mild/Partial Color Deficiency',
      },
    ];

    var pair = colorPairs[currentQuestion];
    bgColor = pair['bg'];
    numberColor = pair['num'];
    colorBlindnessType = pair['type'];

    options = [correctAnswer];
    while (options.length < 3) {
      int n = random.nextInt(9) + 1;
      if (!options.contains(n)) options.add(n);
    }
    options.shuffle();
  }

  void _checkAnswer(int selected) {
    bool correct = selected == correctAnswer;

    if (correct) {
      correctCount++;
    } else {
      wrongTypes.add(colorBlindnessType);
    }

    setState(() {
      currentQuestion++;
      if (currentQuestion < 5) {
        _generateQuestion();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              correctCount: correctCount,
              totalQuestions: 5,
              wrongTypes: wrongTypes,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Color Vision Test",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Skip", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "What number do you see?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    correctAnswer.toString(),
                    style: TextStyle(fontSize: 180, fontWeight: FontWeight.bold, color: numberColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Column(
              children: [
                for (int opt in options)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _checkAnswer(opt),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1C1C1E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                        ),
                        child: Text(opt.toString(), style: const TextStyle(fontSize: 22, color: Colors.white)),
                      ),
                    ),
                  ),
                const SizedBox(height: 25),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final int correctCount;
  final int totalQuestions;
  final List<String> wrongTypes;

  const ResultScreen({
    super.key,
    required this.correctCount,
    required this.totalQuestions,
    required this.wrongTypes,
  });

  @override
  Widget build(BuildContext context) {
    final isPerfect = correctCount == totalQuestions;
    final percentage = (correctCount / totalQuestions * 100).toInt();

    String resultMessage;
    String advice;

    if (isPerfect) {
      resultMessage = "Perfect Vision!";
      advice = "Your color vision appears to be normal. Great job!";
    } else if (percentage >= 60) {
      resultMessage = "Good Vision";
      advice = "Your color vision is mostly normal, but consider consulting an eye specialist.";
    } else {
      resultMessage = "Needs Attention";
      advice = "You may have some color vision deficiency. Please consult an eye care professional.";
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPerfect ? Icons.check_circle : Icons.info_outline,
                  color: isPerfect ? Colors.green : Colors.orange,
                  size: 100,
                ),
                const SizedBox(height: 32),
                Text(
                  resultMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score: $correctCount / $totalQuestions',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    advice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (wrongTypes.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Possible Issues:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...wrongTypes.toSet().map((type) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.fiber_manual_record, color: Colors.orange, size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  type,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const ColorVisionTest()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Retry Test',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Go Home',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// HISTORY SCREEN (Placeholder)
/// ---------------------------
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A2E),
        title: const Text('History'),
      ),
      body: const Center(
        child: Text(
          'No history yet',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }
}

/// ---------------------------
/// SETTINGS SCREEN (Placeholder)
/// ---------------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1A2E),
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text(
          'Settings coming soon',
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      ),
    );
  }
}
