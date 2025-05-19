# Splitmate - Smart Utility Bill Sharing System

Splitmate is a smart utility billing and energy usage tracking system designed for shared houses. It includes a Java-based backend, a Flutter mobile application, and a Raspberry Pi IoT module for device-level energy monitoring.

## 🧩 Project Structure

```
Splitmate/
├── backend/ # Spring Boot backend service
├── mobile-app/ # Flutter mobile application
├── iot-device/ # Raspberry Pi-based energy monitor
```

---

## 🔧 Backend (`/backend`)

A RESTful backend system built with Spring Boot and MyBatis, responsible for user authentication, billing logic, energy data management, and real-time communication via WebSocket.

### ✨ Features
- JWT-based authentication for tenants and landlords
- REST APIs for user, house, billing, and device management
- Real-time energy usage push via WebSocket
- Deployed on AWS EC2 with MySQL database

### 🛠 Tech Stack
- Java 8, Spring Boot 2.7
- MyBatis, MySQL
- WebSocket, JWT
- Docker (optional), AWS EC2

---

## 📱 Mobile App (`/mobile-app`)

Cross-platform Flutter application that allows users to manage their utility bills, monitor device usage, and track shared house expenses.

### ✨ Features
- User login, registration, and profile
- View and split bills by room or person
- Real-time energy usage updates
- Responsive UI for tenants and landlords

### 🛠 Tech Stack
- Flutter 3.x
- Dart, HTTP
- WebSocket integration

---

## 📡 IoT Device (`/iot-device`)

Python-based Raspberry Pi script that monitors energy usage through sensors and sends the data to the backend.

### ✨ Features
- Real-time data collection from connected sensors
- Sends data to backend via HTTP/WebSocket
- Supports offline buffering and syncing

### 🛠 Tech Stack
- Python 3
- Requests, GPIO libraries
- (Optional) Local database for buffering

---

## 🚀 Deployment

### Backend
- Hosted on AWS EC2 (Amazon Linux 2023)
- Nginx reverse proxy (optional)
- MySQL hosted on cloud or locally on EC2

### Mobile App
- Built with Flutter; can be published to Android/iOS stores
- Consumes backend REST APIs and WebSocket

### IoT Device
- Deploy on Raspberry Pi with Python environment
- Configure Wi-Fi and backend endpoint in config file

---

> 

---

## 📂 How to Run

### Backend
```bash
cd backend
# Set up application.yml or application.properties
mvn spring-boot:run
```

### Mobile App

```bash
cd mobile-app
flutter pub get
flutter run
```

### IoT Script

```bash
cd iot-device
python3 main.py
```

## 🏆 Acknowledgements

- University of Adelaide, Master of Computer Science Project
- Thanks to team members: Guanqiao Huang, Jiyun Hao
- Technologies used: Spring Boot, MyBatis, Flutter, Raspberry Pi, TensorFlow (for research)