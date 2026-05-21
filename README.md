# 🤟 HearMe - AI Sign Language Interpreter

> **An intelligent, context-aware sign language translator powered by Edge Vision and Generative AI.**

## 📌 Overview
**HearMe** is a real-time mobile application designed to bridge the communication gap between the deaf community and the hearing world. Unlike traditional apps that offer rigid, word-for-word translation, HearMe utilizes a **Neo-Agentic UI** and a hybrid AI architecture to translate simple sign language shortcuts (tokens) into complete, natural, and context-aware everyday sentences.

## ✨ Key Features
* 🧠 **Contextual Interpretation:** Maps raw sign language tokens into full Arabic and English conversational sentences using Prompt Engineering.
* ⚡ **Edge AI Vision:** Uses a custom TFLite model running directly on the device camera for ultra-low latency gesture detection.
* 🔮 **Neo-Agentic UI:** A futuristic, frosted-glass design with real-time visual feedback loops and intelligent debouncing.
* 🌍 **Bilingual Output:** Instantly generates both Arabic and English translations simultaneously.

## 🛠️ Technology Stack
* **Frontend:** Flutter & Dart
* **Edge AI (Computer Vision):** TensorFlow Lite (TFLite) & Teachable Machine
* **Reasoning Engine (GenAI):** Google Gemini 3.5 Flash API
* **Network & API:** HTTP, RESTful architecture

## 🚀 How It Works (The Hybrid Architecture)
1. **Detect:** The user inputs sign language gestures via the camera.
2. **Filter:** The on-device TFLite model captures frames and identifies tokens with a confidence threshold > 75%.
3. **Debounce:** A smart buffering algorithm cleans the input, adds logical spacing, and waits for the gesture sequence to finish.
4. **Reasoning:** The raw token string is sent to the Gemini API, where a specialized system prompt expands the shortcuts into a polite, full sentence.
5. **Display:** The UI updates instantly with the translated conversational text.

## 💻 Getting Started

### Prerequisites
* Flutter SDK (Version 3.10+)
* Android Studio / VS Code
* A valid Google Gemini API Key
