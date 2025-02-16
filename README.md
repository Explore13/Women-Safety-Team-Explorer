# Suraksha - The Safety App

A smart safety app that detects male and female voices in an audio recording, classifies them, and counts unique voices. If an alert is triggered (e.g., an unusual male-to-female ratio or detected threats), it sends an SMS to trusted contacts. Additional features include real-time gender classification, location-based alerts, and analysis of risk zones. The app aims to enhance safety by enabling proactive alerts and helping users feel secure in various environments.

## Inspiration
Suraksha addresses the critical issue of women’s safety by providing a proactive solution to detect and analyze potential threats. It uses real-time audio classification to identify male and female voices, count unique voices, and monitor surroundings. In high-risk situations, the app sends alerts to trusted contacts, shares live location data, and notifies users of nearby threats or high-risk zones. This solution helps prevent attacks, supports swift intervention, and empowers women with the tools needed to stay safe in various environments.

## Features

- **Gesture Analysis by Voice Command or Pattern:**  
  Trigger SOS alerts and share live location with trusted contacts and local police using **voice commands** on the screen.

- **Real-Time Gender Classification:**  
  Utilize real-time **audio capture** to classify gender through analysis of facial features, body structure, and voice.

- **Gender Distribution from Video and Audio:**  
  Analyze **gender distribution in public spaces** using both **voice data** to monitor and count the number of men and women present.

- **Lone Woman Alert & Get Home Safe:**  
  Trigger alerts when a woman is detected alone at night with no nearby users. Her **live location** is shared with trusted contacts at **10-minute intervals**.

- **Nearby Men Detection & Alerts:**  
  Analyze the **proximity and number of men** around a woman by checking the type of nearest users' location and alerting women of potential threats.

- **Risk Zone Classification & Alerts:**  
  Identify and notify users of **high-risk areas (red zones)** based on the analysis of previous incidents and alerts.

- **Local Helplines & Emergency Contacts:**  
  Contact nearby **police, hospitals, and pharmacies** using **GPS location** and a list of emergency contacts for quick communication.

- **Alert Nearby Users:**  
  When the **Alert button** is triggered, an **alert notification** is sent to nearby app users along with the user’s current location.

## Tech Stack

- **Framework** : Flutter
- **Language**: Dart, Python
- **Cloud services**: Firebase
- **Developer Tools**: VS Code, Android Studio
- **Version control**: Git
- **ML Library Used**: TensorFlow
- **Backend**: Node.js (ExpressJs)
- **SMS Service** : Fast2SMS API

## **Installation & Setup**

 **Clone the repository**:

   ```bash
   git clone https://github.com/Sohampal001/Women-Safety-Team-Explorer.git
   ```
### Backend Setup

To set up the backend:


1. **Navigate to the backend folder**:

   ```bash
   cd Women-Safety-Team-Explorer/backend
   ```

2. **Install dependencies**:
   If using Node.js, run:

   ```bash
   npm install
   ```

3. **Set up environment variables**:  
    Create a `.env` file and add necessary variables.

   ```
   PORT=5000
   YOUR_FAST2SMS_API_KEY=your_fast2sms_api_key
   FIREBASE_API_KEY=your_firebase_api_key
   FIREBASE_AUTH_DOMAIN=your_firebase_auth_domain
   FIREBASE_PROJECT_ID=your_firebase_project_id
   FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
   FIREBASE_M
   ```

4. **Run the backend**:
   ```bash
   npm run dev
   ```


### Frontend Setup

   - Navigate to the Flutter directory and run:
     ```bash
     flutter pub get
     flutter run
     ```


## **API Endpoints**

| Method | Endpoint        | Description                                             |
| ------ | --------------- | ------------------------------------------------------- |
| `POST` | `/api/predict`  | Uploads audio and returns gender classification results, and sends SMS alerts to trusted contacts. |

## **Contributing**

1. Fork the repo
2. Create a new branch (`feature-xyz`)
3. Commit your changes
4. Open a pull request
