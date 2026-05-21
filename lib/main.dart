import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'signal_talk_home.dart'; // calling main menu

// instance var for all cameras
late List<CameraDescription> cameras;

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } catch (e) {
    print("Error initializing cameras: $e");
    cameras = [];
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SignalTalkHome(),
    ),
  );
}
