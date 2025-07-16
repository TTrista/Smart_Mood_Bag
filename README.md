# 🎒 Smart Mood Bag
---

> **Smart Mood Bag** 
is a wearable portable system that integrates a medical-grade sensor device and a cross-platform mobile application.  
> It helps users monitor their heart rate (HR) and heart rate variability (HRV) in daily life and promotes emotional well-being through real-time feedback.

---

## 📦 Project Overview

    This project consists of **two main parts**:

### 1️⃣ Physical Device

- Built-in hospital-grade ECG sensor module (AD8232)
- Measures HR and HRV, analyzes emotional states in real-time
- Wireless data transmission via Bluetooth
- Designed as a fashionable crossbody bag for daily wear — discreet and comfortable

### 2️⃣ Mobile Application

- Developed with **Flutter**, supports both Android and iOS
- Connects with the physical device via Bluetooth
- Receives, displays and records ECG, HR and HRV data
- Provides real-time data visualization: ECG charts and emotional state trends
- Sends push notifications when abnormal stress or emotion patterns are detected

---
## 🌟 Key Features
- Medical-grade accuracy: Uses AD8232 ECG chip for reliable heart data.

- Always-on monitoring: Stay aware of stress or emotional changes.

- Discreet & stylish: Blends into daily outfits as a fashionable accessory.

- Wireless & real-time: Smooth Bluetooth connection with mobile app.

- Open-source: Both hardware and software source code are available for further research and development.

---

## 🖼️ Wearing Method

> ![Wearing Style](show_demo\wearingmethod.jpg)  

 The Smart Mood Bag is designed as a small crossbody bag to make ECG data collection comfortable and unobtrusive.
It can be worn over everyday clothing and is suitable for both indoor and outdoor activities.

---

## 🎥 Project Promo Video

> [![Watch the promo video](show_demo\cover.jpg)](https://www.youtube.com/watch?v=0eqL12BLzN0)  
> Click to watch the official project introduction video.

---
## 📱App overview

---

## 📂 Project Structure

Smart_Mood_Bag/
├── lib/ # Flutter App source code
├── android/ # Android platform configuration
├── ios/ # iOS platform configuration
├── firmware/ # MCU firmware source code (ESP32/Arduino)
├── docs/ # Documentation and resource files (images, video thumbnails)
├── build/ # Generated build outputs (do not commit)
├── pubspec.yaml # Flutter dependency configuration
├── LICENSE
├── README.md

---

## 🚀 Getting Started

1. **Clone this repository:**
   ```bash
   git clone https://github.com/TTrista/Smart_Mood_Bag.git

2. **Install dependencies and run the app:**

    ```bash
    flutter pub get
    flutter run

3. **Build APK for distribution:**
    ```bash
    flutter build apk --release

---

## 📣 Contributing & Contact
We welcome collaboration! Please ⭐️ star this repo if you find it useful.

Feel free to open an issue for questions, ideas, or technical support.

For business or research collaboration, please reach out via Issues or pull requests.

---

## 📝 License

This project is licensed under the MIT License. See LICENSE for details.

---