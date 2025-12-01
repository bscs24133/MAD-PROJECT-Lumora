import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:math';
import 'firebase_service.dart';
import 'settingandhistory.dart';
class CameraScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScannerPage({required this.cameras, super.key});

  @override
  State<CameraScannerPage> createState() => _CameraScannerPageState();
}
class _CameraScannerPageState extends State<CameraScannerPage> {
  final FirebaseService _firebaseService = FirebaseService();
  Color? detectedColor;
  String detectedColorName = "Tap to detect color";
  String detectedHex = "";
  String detectedRgb = "";
  Offset? lastTapPosition;

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

  // THEIR WORKING DETECTION METHOD - INTEGRATED INTO YOUR CODE
  Future<void> _detectColor(Offset position) async {
    if (controller == null || !controller!.value.isInitialized) {
      return;
    }

    try {
      final image = await controller!.takePicture();
      final bytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // Get the camera preview size
        final size = MediaQuery.of(context).size;
        final deviceRatio = size.width / size.height;
        final cameraRatio = controller!.value.aspectRatio;

        // Calculate the actual image coordinates
        int x, y;

        if (cameraRatio > deviceRatio) {
          // Image is wider, height matches
          final scale = decodedImage.height / size.height;
          final imageWidth = size.width * scale;
          final leftOffset = (decodedImage.width - imageWidth) / 2;

          x = (leftOffset + (position.dx * scale)).toInt();
          y = (position.dy * scale).toInt();
        } else {
          // Image is taller, width matches
          final scale = decodedImage.width / size.width;
          final imageHeight = size.height * scale;
          final topOffset = (decodedImage.height - imageHeight) / 2;

          x = (position.dx * scale).toInt();
          y = (topOffset + (position.dy * scale)).toInt();
        }

        // Clamp coordinates to image bounds
        x = x.clamp(0, decodedImage.width - 1);
        y = y.clamp(0, decodedImage.height - 1);

        // Get pixel color
        final pixel = decodedImage.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        final detectedColorValue = Color.fromRGBO(r, g, b, 1);
        final colorName = _getColorName(r, g, b);
        final hexValue = '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
            '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
            '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
        final rgbValue = 'RGB($r, $g, $b)';
        setState(() {
          detectedColor = detectedColorValue;
          detectedColorName = colorName;
          detectedHex = hexValue;
          detectedRgb = rgbValue;
          lastTapPosition = position;
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? userEmail = prefs.getString("activeEmail");

        if (userEmail != null && userEmail.isNotEmpty) {
          await _firebaseService.saveColorToHistory(
            userEmail: userEmail,
            color:detectedColorValue,
            colorName: detectedColorName,
            hex: detectedHex,
            rgb:detectedRgb,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Color saved to history!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

    } catch (e) {
      print('Error detecting color: $e');
    }
  }

  String _getColorName(int r, int g, int b) {
    // Convert RGB to HSL for better color detection
    double rNorm = r / 255.0;
    double gNorm = g / 255.0;
    double bNorm = b / 255.0;

    double max = [rNorm, gNorm, bNorm].reduce((a, b) => a > b ? a : b);
    double min = [rNorm, gNorm, bNorm].reduce((a, b) => a < b ? a : b);
    double delta = max - min;

    double lightness = (max + min) / 2;
    double saturation = delta == 0 ? 0 : delta / (1 - (2 * lightness - 1).abs());

    // Calculate hue
    double hue = 0;
    if (delta != 0) {
      if (max == rNorm) {
        hue = 60 * (((gNorm - bNorm) / delta) % 6);
      } else if (max == gNorm) {
        hue = 60 * (((bNorm - rNorm) / delta) + 2);
      } else {
        hue = 60 * (((rNorm - gNorm) / delta) + 4);
      }
    }
    if (hue < 0) hue += 360;

    // Handle grayscale colors
    if (saturation < 0.1) {
      if (lightness < 0.2) return 'Black';
      if (lightness > 0.8) return 'White';
      return 'Gray';
    }

    // Special handling for pink (light red with high lightness)
    if ((hue >= 330 || hue < 30) && lightness > 0.6 && saturation > 0.2) {
      return 'Pink';
    }

    // Special handling for brown (dark orange/red-orange)
    if (hue >= 10 && hue < 50 && lightness < 0.5 && saturation > 0.2) {
      return 'Brown';
    }

    // Determine color name based on hue ranges
    if (hue >= 345 || hue < 10) return 'Red';
    if (hue < 25) return 'Red-Orange';
    if (hue < 30) return 'Orange';
    if (hue < 40) return 'Tan';
    if (hue < 70) return 'Yellow';
    if (hue < 80) return 'Yellow-Green';
    if (hue < 165) return 'Green';
    if (hue < 200) return 'Cyan';
    if (hue < 240) return 'Blue';
    if (hue < 260) return 'Blue-Purple';
    if (hue < 290) return 'Purple';
    if (hue < 320) return 'Magenta';
    if (hue < 330) return 'Pink';
    return 'Red';
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
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview with Tap Detection
          // Camera Preview with Tap Detection
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix([
                1, 0, 0, 0, 0,
                0, 1, 0, 0, 0,
                0, 0, 1, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: GestureDetector(
                onTapDown: (details) {
                  _detectColor(details.localPosition);
                },
                child: CameraPreview(controller!),
              ),
            ),
          ),

          // Back Button
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

          // Tap indicator circle (shows where you tapped)
          if (lastTapPosition != null)
            Positioned(
              left: lastTapPosition!.dx - 20,
              top: lastTapPosition!.dy - 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),

          // Detected Color Display (Above Capture Button)
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: detectedColor ?? Colors.grey.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (detectedColor ?? Colors.grey).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      detectedColorName,
                      style: TextStyle(
                        color: (detectedColor?.computeLuminance() ?? 0.5) > 0.5
                            ? Colors.black
                            : Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (detectedHex.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        detectedHex,
                        style: TextStyle(
                          color: (detectedColor?.computeLuminance() ?? 0.5) > 0.5
                              ? Colors.black54
                              : Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (detectedRgb.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detectedRgb,
                        style: TextStyle(
                          color: (detectedColor?.computeLuminance() ?? 0.5) > 0.5
                              ? Colors.black54
                              : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Capture Button
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
  final FirebaseService _firebaseService = FirebaseService();
  Color? detectedColor;
  String detectedColorName = "Tap to detect color";
  String detectedHex = "";
  String detectedRgb = "";
  Offset? lastTapPosition;

  Color dominantColor = Colors.white;
  String hex = "", rgb = "", shade = "";
  bool isLoading = true;

  @override

  void initState() {
    super.initState();
    // Don't call _detectColor on init since it needs a tap position
    setState(() {
      isLoading = false;
    });
  }

  GlobalKey _imageKey = GlobalKey(); // Add this at the top of the class

  void _detectColor(Offset tapPosition) async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return;

      // Get the actual rendered size of the image widget
      final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        print("RenderBox is null");
        return;
      }

      // Get the actual displayed size
      final widgetWidth = renderBox.size.width;
      final widgetHeight = renderBox.size.height;

      print("Widget size: $widgetWidth x $widgetHeight");
      print("Image size: ${image.width} x ${image.height}");
      print("Tap position: ${tapPosition.dx}, ${tapPosition.dy}");

      // Image dimensions
      final imageWidth = image.width;
      final imageHeight = image.height;

      // Calculate aspect ratios
      final imageAspect = imageWidth / imageHeight;
      final widgetAspect = widgetWidth / widgetHeight;

      double scale;
      double offsetX = 0;
      double offsetY = 0;

      if (widgetAspect > imageAspect) {
        // Widget is wider - image height fills, width is centered
        scale = widgetHeight / imageHeight;
        final scaledWidth = imageWidth * scale;
        offsetX = (widgetWidth - scaledWidth) / 2;
      } else {
        // Widget is taller - image width fills, height is centered
        scale = widgetWidth / imageWidth;
        final scaledHeight = imageHeight * scale;
        offsetY = (widgetHeight - scaledHeight) / 2;
      }

      print("Scale: $scale, Offset: $offsetX, $offsetY");

      // Map tap coordinates to image coordinates
      final imageX = ((tapPosition.dx - offsetX) / scale).round().clamp(0, imageWidth - 1);
      final imageY = ((tapPosition.dy - offsetY) / scale).round().clamp(0, imageHeight - 1);

      print("Image coordinates: $imageX, $imageY");

      // Get pixel color
      final pixel = image.getPixel(imageX, imageY);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      print("RGB: $r, $g, $b");
      final detectedColorValue = Color.fromRGBO(r, g, b, 1);
      final colorName = _getShadeName(r, g, b);
      final hexValue = '#${r.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${g.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          '${b.toRadixString(16).padLeft(2, '0').toUpperCase()}';
      final rgbValue = 'RGB($r, $g, $b)';
      setState(() {
        detectedColor = detectedColorValue;
        detectedColorName = colorName;
        detectedHex = hexValue;
        detectedRgb = rgbValue;
        lastTapPosition = tapPosition;
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userEmail = prefs.getString("activeEmail");

      if (userEmail != null && userEmail.isNotEmpty) {
        await _firebaseService.saveColorToHistory(
          userEmail: userEmail,
          color: detectedColorValue,
          colorName:detectedColorName,
          hex:detectedHex,
          rgb:detectedRgb,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Color saved to history!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch(e) {
      print("Error detecting color on upload: $e");
    }
  }
  String _getShadeName(int r, int g, int b) {
    // Essential color database with ~45 colors
    final Map<String, List<int>> colorDatabase = {
      // ==================== REDS ====================
      'Red': [255, 0, 0],
      'Dark Red': [139, 0, 0],
      'Crimson': [220, 20, 60],
      'Firebrick': [178, 34, 34],
      'Tomato': [255, 99, 71],
      'Cherry Red': [222, 49, 99],
      'Rose Red': [194, 30, 86],
      'Ruby Red': [155, 17, 30],
      'Blood Red': [102, 0, 0],
      'Candy Apple': [255, 8, 0],
      'Ferrari Red': [255, 40, 0],
      'Maroon': [128, 0, 0],

      'Orange': [255, 165, 0],
      'Dark Orange': [255, 140, 0],
      'Coral': [255, 127, 80],
      'Peach': [255, 218, 185],
      'Tangerine': [242, 133, 0],
      'Burnt Orange': [204, 85, 0],
      'Carrot': [237, 145, 33],
      'Pumpkin': [255, 117, 24],
      'Marigold': [234, 162, 33],
      'Persimmon': [236, 88, 0],

      'Yellow': [255, 255, 0],
      'Light Yellow': [255, 255, 224],
      'Lemon': [255, 247, 0],
      'Gold': [255, 215, 0],
      'Mustard': [255, 219, 88],
      'Goldenrod': [218, 165, 32],
      'Saffron': [244, 196, 48],
      'Cream': [255, 253, 208],
      'Daffodil': [255, 255, 49],
      'Banana': [255, 225, 53],

      'Green': [0, 128, 0],
      'Dark Green': [0, 100, 0],
      'Lime': [0, 255, 0],
      'Forest Green': [34, 139, 34],
      'Olive': [128, 128, 0],
      'Mint': [152, 255, 152],
      'Teal': [0, 128, 128],
      'Chartreuse': [127, 255, 0],
      'Lawn Green': [124, 252, 0],
      'Kelly Green': [76, 187, 23],
      'Emerald': [80, 200, 120],
      'Shamrock': [0, 158, 96],
      'Pistachio': [147, 197, 114],
      'Sage': [188, 184, 138],
      'Moss Green': [138, 154, 91],

      'Cyan': [0, 255, 255],
      'Aqua': [0, 255, 255],
      'Turquoise': [64, 224, 208],
      'Medium Turquoise': [72, 209, 204],
      'Dark Turquoise': [0, 206, 209],
      'Robin Egg Blue': [0, 204, 204],
      'Caribbean Blue': [0, 204, 204],

      'Blue': [0, 0, 255],
      'Dark Blue': [0, 0, 139],
      'Navy': [0, 0, 128],
      'Royal Blue': [65, 105, 225],
      'Sky Blue': [135, 206, 235],
      'Light Blue': [173, 216, 230],
      'Dodger Blue': [30, 144, 255],
      'Steel Blue': [70, 130, 180],
      'Cornflower Blue': [100, 149, 237],
      'Cobalt Blue': [0, 71, 171],
      'Sapphire': [15, 82, 186],
      'Azure': [240, 255, 255],
      'Ice Blue': [175, 238, 238],
      'Carolina Blue': [86, 160, 211],
      'Denim': [21, 96, 189],

      'Purple': [128, 0, 128],
      'Dark Purple': [48, 25, 52],
      'Indigo': [75, 0, 130],
      'Violet': [238, 130, 238],
      'Lavender': [230, 230, 250],
      'Orchid': [218, 112, 214],
      'Medium Purple': [147, 112, 219],
      //'Amethyst': [153, 102, 204],

      'Pink': [255, 192, 203],
      'Hot Pink': [255, 105, 180],
      'Deep Pink': [255, 20, 147],
      'Rose': [255, 0, 127],
      'Blush': [222, 93, 131],
      'Bubblegum': [255, 193, 204],
      'Flamingo': [252, 142, 172],
      'Carnation Pink': [255, 166, 201],

      'Brown': [165, 42, 42],
      'Dark Brown': [101, 67, 33],
      'Sienna': [160, 82, 45],
      'Chocolate': [210, 105, 30],
      'Tan': [210, 180, 140],
      'Beige': [245, 245, 220],
      'Walnut': [119, 63, 26],


      'Black': [0, 0, 0],
      'White': [255, 255, 255],
      'Gray': [128, 128, 128],
      'Silver': [192, 192, 192],
      'Charcoal': [54, 69, 79],
      'Light Gray': [211, 211, 211],
      'Ash Gray': [178, 190, 181],
      'Ivory': [255, 255, 240]
    };

    // Find the closest color using Euclidean distance
    String closestColorName = 'Unknown';
    double minDistance = double.infinity;

    colorDatabase.forEach((name, rgb) {
      // Calculate Euclidean distance in 3D RGB space
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
    final accessibilitySettings = Provider.of<AccessibilitySettings>(context);
    final isHighContrast = accessibilitySettings.highContrast;
    final colorVisionMode = accessibilitySettings.colorVisionMode;

    return Scaffold(
      backgroundColor: isHighContrast ? HighContrastTheme.background : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),

      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Image with tap detection - CORRECTED
              Center(
                child: GestureDetector(
                  onTapDown: (details) {
                    // Get the position relative to the GestureDetector
                    _detectColor(details.localPosition);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    height: 300,
                    color: Colors.black, // background for empty space
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Large Color Display
              Container(
                key: _imageKey,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: detectedColor ?? Colors.grey,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (detectedColor ?? Colors.grey).withOpacity(0.5),
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
                        detectedColorName,
                        style: TextStyle(
                          color: (detectedColor?.computeLuminance() ?? 0.5) > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detectedHex,
                        style: TextStyle(
                          color: (detectedColor?.computeLuminance() ?? 0.5) > 0.5
                              ? Colors.black54
                              : Colors.white70,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 60),

              // Color Details Section
              // Color Details Section - WRAPPED WITH ColorFiltered
              ColorFiltered(
                colorFilter: ColorFilter.matrix(ColorBlindFilters.getFilter(colorVisionMode)),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Color Details',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Detail Cards
                    if (detectedHex.isNotEmpty)
                      _buildDetailCard('HEX Code', detectedHex),
                    if (detectedRgb.isNotEmpty)
                      _buildDetailCard('RGB Values', detectedRgb),
                    if (detectedColorName.isNotEmpty)
                      _buildDetailCard('Closest Shade', detectedColorName),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override

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


/// ----