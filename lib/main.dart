import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const CountdownApp());
}

class CountdownApp extends StatefulWidget {
  const CountdownApp({super.key});

  @override
  State<CountdownApp> createState() => _CountdownAppState();
}

class _CountdownAppState extends State<CountdownApp> {
  bool isDark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advanced Countdown Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: isDark ? Brightness.dark : Brightness.light,
        fontFamily: 'Roboto',
        primarySwatch: Colors.deepPurple,
      ),
      home: CountdownScreen(
        toggleTheme: () {
          setState(() {
            isDark = !isDark;
          });
        },
        isDark: isDark,
      ),
    );
  }
}

class CountdownScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDark;

  const CountdownScreen({super.key, required this.toggleTheme, required this.isDark});

  @override
  State<CountdownScreen> createState() => _CountdownScreenState();
}

class _CountdownScreenState extends State<CountdownScreen> with SingleTickerProviderStateMixin {
  int minutes = 0;
  int seconds = 0;
  int totalSeconds = 0;
  Timer? timer;
  bool isRunning = false;
  bool isCompleted = false;

  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    loadLastTimer();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  Future<void> saveLastTimer(int minutes, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastMinutes', minutes);
    await prefs.setInt('lastSeconds', seconds);
  }

  Future<void> loadLastTimer() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      minutes = prefs.getInt('lastMinutes') ?? 0;
      seconds = prefs.getInt('lastSeconds') ?? 0;
      totalSeconds = (minutes * 60) + seconds;
    });
  }

  void startTimer() {
    if (timer != null) timer!.cancel();

    setState(() {
      isRunning = true;
      isCompleted = false;
      totalSeconds = (minutes * 60) + seconds;
    });

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (minutes == 0 && seconds == 0) {
        timer.cancel();
        setState(() {
          isRunning = false;
          isCompleted = true;
        });
      } else {
        setState(() {
          if (seconds == 0) {
            minutes--;
            seconds = 59;
          } else {
            seconds--;
          }
        });
        saveLastTimer(minutes, seconds);
      }
    });
  }

  void stopTimer() {
    if (timer != null) timer!.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    if (timer != null) timer!.cancel();
    setState(() {
      minutes = 0;
      seconds = 0;
      totalSeconds = 0;
      isRunning = false;
      isCompleted = false;
    });
    saveLastTimer(0, 0);
  }

  void setPreset(int sec) {
    if (timer != null) timer!.cancel();
    setState(() {
      minutes = sec ~/ 60;
      seconds = sec % 60;
      totalSeconds = sec;
      isRunning = false;
      isCompleted = false;
    });
    saveLastTimer(minutes, seconds);
  }

  @override
  void dispose() {
    if (timer != null) timer!.cancel();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    int remaining = (minutes * 60) + seconds;
    double progress = totalSeconds == 0 ? 0 : remaining / totalSeconds;

    Color ringColor;
    if (progress > 0.5) {
      ringColor = Colors.greenAccent;
    } else if (progress > 0.2) {
      ringColor = Colors.orangeAccent;
    } else {
      ringColor = Colors.redAccent;
    }

    double timerSize = screenWidth < 600 ? 220 : 300;
    double fontSize = screenWidth < 600 ? 48 : 64;
    double buttonFont = screenWidth < 600 ? 14 : 16;
    double inputWidth = screenWidth < 600 ? 80 : 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text("⏳ Countdown Timer"),
        actions: [
          IconButton(
            icon: Icon(widget.isDark ? Icons.wb_sunny : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          )
        ],
      ),
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(Colors.purple, Colors.pink, _bgController.value)!,
                  Color.lerp(Colors.orange, Colors.blue, _bgController.value)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circular Timer
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: timerSize,
                          height: timerSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ringColor.withOpacity(0.7),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 14,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation(ringColor),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}",
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 8,
                                    color: Colors.black45,
                                    offset: Offset(2, 2),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${(progress * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Input Fields
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildInputField("Min", inputWidth, (val) {
                          minutes = int.tryParse(val) ?? 0;
                          totalSeconds = (minutes * 60) + seconds;
                        }),
                        const SizedBox(width: 20),
                        _buildInputField("Sec", inputWidth, (val) {
                          seconds = int.tryParse(val) ?? 0;
                          totalSeconds = (minutes * 60) + seconds;
                        }),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Preset Buttons
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _presetButton("30s", 30),
                        _presetButton("1m", 60),
                        _presetButton("5m", 300),
                        _presetButton("10m", 600),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Control Buttons
                    Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildButton(Icons.play_arrow, "Start",
                            isRunning ? null : startTimer, Colors.greenAccent, buttonFont),
                        _buildButton(Icons.pause, "Pause",
                            isRunning ? stopTimer : null, Colors.orangeAccent, buttonFont),
                        _buildButton(Icons.stop, "Reset",
                            resetTimer, Colors.redAccent, buttonFont),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Custom Input Field
  Widget _buildInputField(String hint, double width, Function(String) onChanged) {
    return SizedBox(
      width: width,
      child: TextField(
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (val) {
          setState(() {
            onChanged(val);
          });
        },
      ),
    );
  }

  // Custom Button
  Widget _buildButton(
      IconData icon, String label, VoidCallback? onPressed, Color color, double fontSize) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: fontSize)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
      ),
    );
  }

  // Preset Button
  Widget _presetButton(String label, int seconds) {
    return ElevatedButton(
      onPressed: () => setPreset(seconds),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white24,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
