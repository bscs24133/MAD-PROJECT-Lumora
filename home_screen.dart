import 'package:firebase_core/firebase_core.dart';
import 'firebase_service.dart';
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
import 'camera_upload.dart';
import 'package:provider/provider.dart';
import 'settingandhistory.dart';
import 'quiz.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AccessibilitySettings(),
      child: LumoraAppWithAuth(),
    ),
  );
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
          ? const HomeScreen() // Goes to second code's HomeScreen
          : AuthIntroScreen(), // Shows auth flow first
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


  @override

  Widget build(BuildContext context) {
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
      child: Scaffold(
        backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,
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


            return Container(
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
                  child: Icon(
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
                trailing: null,
              ),

            );
          },
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
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
      child: Scaffold(
        backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,

        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
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
  @override
  Widget build(BuildContext context) {
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
      child: Scaffold(
        backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AuthIntroScreen()),
              );
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
      child: Scaffold(
        backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AuthWelcomeScreen()),
              );
            },
          ),
          title: Text("Log In", style: TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
        ),
      ),
    );
  }
}

// ===============================================
// SIGN UP SCREEN
// ===============================================
// ===============================================
// SIGN UP SCREEN
// ===============================================
class AuthSignUpScreen extends StatefulWidget {
  @override
  State<AuthSignUpScreen> createState() => _AuthSignUpScreenState();
}

class _AuthSignUpScreenState extends State<AuthSignUpScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLoading = false;

  Future<void> saveNewUser(String name, String email, String pass) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("users") ?? [];

    Map<String, dynamic> newUser = {
      "name": name,
      "email": email,
      "password": pass,
    };

    saved.add(jsonEncode(newUser));
    prefs.setStringList("users", saved);

    prefs.setBool("loggedIn", true);
    prefs.setString("activeEmail", email);
  }

  @override
  Widget build(BuildContext context) {
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
      child: Scaffold(
        backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: isLoading ? null : () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AuthWelcomeScreen()),
              );
            },
          ),
          title: Text("Sign Up", style: TextStyle(color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
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
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : Text(
                        "Create Account",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      onPressed: isLoading ? null : () async {
                        // Prevent multiple clicks
                        setState(() => isLoading = true);

                        try {
                          // Validation
                          if (name.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your name')),
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          if (email.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your email')),
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          if (!email.text.trim().contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid email')),
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          if (pass.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a password')),
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          if (pass.text.trim().length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password must be at least 6 characters')),
                            );
                            setState(() => isLoading = false);
                            return;
                          }

                          // Check if email already exists
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          List<String> saved = prefs.getStringList("users") ?? [];

                          for (var u in saved) {
                            Map user = jsonDecode(u);
                            if (user["email"] == email.text.trim()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This email is already registered. Please use a different email or log in.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => isLoading = false);
                              return;
                            }
                          }

                          // Save new user
                          await saveNewUser(
                            name.text.trim(),
                            email.text.trim(),
                            pass.text.trim(),
                          );

                          // Navigate to home
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                                (route) => false,
                          );
                        } catch (e) {
                          setState(() => isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error creating account: $e'),
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
// END OF AUTH SCREENS
// ===============================================
class LumoraAppMain extends StatelessWidget {
  const LumoraAppMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lumora',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const HomeScreen(),
    );
  }
}

/// -------------------
/// HOME SCREEN
/// -------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override

  Widget build(BuildContext context) {
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
      child: Scaffold(
        backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,


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
                      child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 24),
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ColorHistoryScreen()));
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                },
              ),
              const Divider(color: Colors.white24, thickness: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white70),
                title: const Text('Log Out', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () async {
                  SharedPreferences prefs = await SharedPreferences.getInstance();

                  // Just mark as logged out - keep all users
                  prefs.setBool("loggedIn", false);
                  prefs.remove("activeEmail");
                  // DON'T remove users - they stay in storage

                  // Show a confirmation message or just close the drawer
                  Navigator.pop(context); // Close the drawer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                },
              ),

// Add this new tile to go to the starting page
              ListTile(
                leading: const Icon(Icons.login, color: Colors.white70),
                title: const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 16)),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => AuthWelcomeScreen()),
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
                      child: const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
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
                              'User',
                              style: TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.people, color: Color(0xFF60A5FA), size: 14),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
              // Main Content
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