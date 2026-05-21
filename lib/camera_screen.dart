import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:http/http.dart' as http;

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? controller;
  String _result = "Waiting...";
  bool _isProcessing = false;

  String _charBuffer = "";
  String _lastDetectedLabel = "";
  Timer? _debounceTimer;
  bool _isLoadingAI = false;

  String _arabicResult = "...في انتظار لغة الإشارة";
  String _englishResult = "Waiting for contextual translation...";

  // للأنيماشين بتاع الـ Agent شعار
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _loadModel();
    _initializeCamera();

    // إعداد أنيماشين النبض لشعار الـ AI
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(_pulseController);
  }

  // 1. تحميل الموديل
  Future<void> _loadModel() async {
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  // 2. تشغيل الكاميرا
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    ); // High resolution for better UI

    try {
      await controller!.initialize();
      if (!mounted) return;
      setState(() {});

      controller!.startImageStream((CameraImage image) {
        if (_isProcessing || _isLoadingAI) return;
        _isProcessing = true;

        Tflite.runModelOnFrame(
              bytesList: image.planes.map((plane) => plane.bytes).toList(),
              imageHeight: image.height,
              imageWidth: image.width,
              imageMean: 127.5,
              imageStd: 127.5,
              rotation: 90,
              numResults: 1,
              threshold: 0.1,
            )
            .then((recognitions) {
              _processRecognitions(recognitions);
              _isProcessing = false;
            })
            .catchError((e) {
              _isProcessing = false;
            });
      });
    } catch (e) {
      print("Camera error: $e");
    }
  }

  // 3. معالجة وتجميع الحروف الملقوطة من الكاميرا
  void _processRecognitions(List<dynamic>? recognitions) {
    if (recognitions != null && recognitions.isNotEmpty) {
      String rawLabel = recognitions.first['label'] ?? "";
      double confidence = recognitions.first['confidence'] ?? 0.0;
      if (confidence > 0.75) {
        String cleanLetter = rawLabel.replaceAll(RegExp(r'[0-9]'), '').trim();

        if (cleanLetter.isNotEmpty && cleanLetter != _lastDetectedLabel) {
          setState(() {
            _lastDetectedLabel = cleanLetter;
            _charBuffer += cleanLetter + " ";
            _result = cleanLetter;
          });
          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
            if (_charBuffer.trim().isNotEmpty) {
              _sendToGeminiAgent(_charBuffer.trim());
            }
          });
        }
      }
    }
  }

  // 4. إرسال الحروف المجمعة لـ Gemini Agent (الوكيل الذكي للحياة اليومية)
  Future<void> _sendToGeminiAgent(String rawText) async {
    if (rawText.isEmpty) return;

    setState(() {
      _isLoadingAI = true;
    });

    const apiKey = "AIzaSyDwe84W8uHPyZ2alO2Rg00WxhHuqRzMtqU";
    const url =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent?key=$apiKey";
    final prompt =
        """
    You are an expert AI conversational interpreter for a sign language app called HearMe.
    The user is inputting a sequence of Arabic letters as shortcuts: "$rawText".
    Map these logically to common daily life concepts and expand them into a complete, polite everyday sentence.
    
    You MUST respond in BOTH Arabic and English exactly in the following format:
    Arabic: [الجملة العربية هنا]
    English: [The English sentence here]
    """;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        String aiResponse =
            responseBody['candidates'][0]['content']['parts'][0]['text'];

        String arSentence = "...في انتظار لغة الإشارة";
        String enSentence = "Waiting for contextual translation...";

        final lines = aiResponse.split('\n');
        for (var line in lines) {
          if (line.trim().startsWith('Arabic:')) {
            arSentence = line.replaceFirst('Arabic:', '').trim();
          } else if (line.trim().startsWith('English:')) {
            enSentence = line.replaceFirst('English:', '').trim();
          }
        }

        setState(() {
          _arabicResult = arSentence;
          _englishResult = enSentence;
          _charBuffer = ""; // تصفير البافر استعداداً للمحادثة القادمة
          _isLoadingAI = false;
        });
      } else {
        // 🌟 التعديل الثالث: مسك سبب الرفض الحقيقي من جوجل
        final errorBody = json.decode(response.body);
        String realError = errorBody['error']['message'] ?? "Unknown API Error";
        throw Exception(realError);
      }
    } catch (e) {
      setState(() {
        _isLoadingAI = false;
        _arabicResult = "خطأ في الاتصال بالوكيل الذكي";
        _englishResult = "Error: ${e.toString().replaceAll('Exception: ', '')}";
      });
      print("Gemini Error: $e");
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    Tflite.close();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // خلفية داكنة فخمة
      body: Column(
        children: [
          // 1. الجزء العلوي (الكاميرا والقائمة الجانبية)
          Expanded(
            flex: 6,
            child: Row(
              children: [
                // الكاميرا كـ بانل عائمة في اليسار
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 40,
                      bottom: 20,
                      left: 15,
                      right: 10,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.5),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: CameraPreview(controller!),
                          ),
                          // شارة التوكين العائمة فوق على الشمال
                          Positioned(
                            top: 15,
                            left: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.purpleAccent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                "Token: $_result",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // القائمة الجانبية العمودية النضيفة على اليمين
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 30,
                        ),
                        RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            "HEARME - AI INTERPRETER",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 30,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. الجزء السفلي (لوحة تحكم AI الصلبة والنضيفة)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1D062E), // بنفسجي غامق صلب (مش زجاجي)
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const Text(
                    "(AI Agent) الترجمة الذكية اليومية",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // النص العربي النيون
                  Expanded(
                    child: Center(
                      child: Text(
                        _arabicResult,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white, // أبيض لسهولة القراءة
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    child: Divider(color: Colors.purple, thickness: 1),
                  ),
                  // النص الإنجليزي الأنيق
                  Expanded(
                    child: Center(
                      child: Text(
                        _englishResult,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC393FD), // بنفسجي فاتح
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // البافر الصغير تحت خالص
                  Text(
                    "Buffer Input: $_charBuffer",
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

          // 3. مؤشر التحميل النيون النحيف (بيظهر لما جميني يفكر)
          if (_isLoadingAI)
            const LinearProgressIndicator(
              color: Color.fromARGB(255, 42, 35, 93),
              backgroundColor: Colors.transparent,
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}
