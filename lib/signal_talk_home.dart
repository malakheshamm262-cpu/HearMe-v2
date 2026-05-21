import 'package:flutter/material.dart';
import 'camera_screen.dart'; // تأكدي إن اسم الفايل ده مطابق لاسم فايل الكاميرا عندك

class SignalTalkHome extends StatefulWidget {
  const SignalTalkHome({super.key});

  @override
  State<SignalTalkHome> createState() => _SignalTalkHomeState();
}

class _SignalTalkHomeState extends State<SignalTalkHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // أنيميشن النبض (Pulse) عشان اللوجو ينور ويطفي بهدوء
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 2.0, end: 15.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // خلفية متدرجة فخمة تناسب الـ AI
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F021A), // بنفسجي داكن جداً فوق
              Color(0xFF1D062E), // بنفسجي الكاميرا تحت
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. اللوجو المتحرك المضيء
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF26264C).withOpacity(0.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purpleAccent.withOpacity(0.5),
                        blurRadius: _glowAnimation.value * 2,
                        spreadRadius: _glowAnimation.value,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.purpleAccent.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  // أيقونة لغة الإشارة جاهزة من فلوتر
                  child: const Icon(
                    Icons.sign_language,
                    size: 80,
                    color: Colors.white,
                  ),
                );
              },
            ),
            const SizedBox(height: 60),

            // 2. اسم التطبيق بخط عريض ومسافات واسعة (Premium Typography)
            const Text(
              "HEARME",
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 10.0,
              ),
            ),
            const SizedBox(height: 12),

            // 3. الوصف أو الـ Tagline
            Text(
              "AI SIGN LANGUAGE INTERPRETER",
              style: TextStyle(
                fontSize: 12,
                color: Colors.purple[200],
                letterSpacing: 4.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 80),

            // 4. زرار الـ START النيون الفخم
            GestureDetector(
              onTap: () {
                // الانتقال لشاشة الكاميرا
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.purpleAccent,
                      Color(0xFF8E24AA),
                    ], // تدرج زرار البدء
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "START AGENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 5. لمسة أخيرة تحت (Powered by Gemini)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.grey, size: 14),
                SizedBox(width: 6),
                Text(
                  "Powered by AI (Gemini agent)",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
