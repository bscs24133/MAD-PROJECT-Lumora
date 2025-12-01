import 'package:flutter/material.dart';
import 'dart:math';
import 'home_screen.dart';
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
        child:SingleChildScrollView(
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
        child:SingleChildScrollView(
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