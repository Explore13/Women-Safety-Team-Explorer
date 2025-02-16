// import 'dart:async';
// import 'dart:math';
// import 'package:background_sms/background_sms.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:women_safety/record/recording.dart';
// import 'package:women_safety/db/db_services.dart';
// import 'package:women_safety/model/contactsm.dart';

// class VoiceRecognitionService {
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   final AudioRecorder _audioRecorder = AudioRecorder();
//   bool _isListening = false;
//   bool _hasStarted = false;
//   Position? _currentPosition;
//   String? _currentAddress;

//   void startListening() async {
//     await _initializeSpeechRecognition();
//     _startContinuousListening();
//   }

//   Future<void> _initializeSpeechRecognition() async {
//     await _speech.initialize(
//       onStatus: (status) {
//         if (status == 'listening') {
//           if (!_hasStarted) {
//             Fluttertoast.showToast(msg: "Listening started");
//             _hasStarted = true;
//           }
//         } else if (status == 'done') {
//           // Automatically restart listening if it stops
//           _startContinuousListening();
//         }
//       },
//       onError: (error) {
//         Fluttertoast.showToast(msg: "Speech recognition error: $error");
//         _startContinuousListening();
//       },
//     );
//   }

//   void _startContinuousListening() {
//     if (!_isListening) {
//       _isListening = true;
//       _speech.listen(
//         onResult: (val) async {
//           if (val.recognizedWords.toLowerCase().contains('me too')) {
//             await _sendLocationToContacts();
//             await _audioRecorder.startRecording();
//             Fluttertoast.showToast(msg: "Location sent and recording started.");
//           }
//         },
//       );
//     }
//   }

//   Future<void> _sendLocationToContacts() async {
//     if (_currentPosition == null) {
//       _currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//     }

//     if (_currentPosition != null) {
//       List<Placemark> placemarks = await placemarkFromCoordinates(
//         _currentPosition!.latitude,
//         _currentPosition!.longitude,
//       );
//       Placemark place = placemarks[0];
//       _currentAddress =
//           "${place.locality}, ${place.postalCode}, ${place.subLocality}";

//       String messageBody =
//           "https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude}%2C${_currentPosition!.longitude}. $_currentAddress";

//       if (await _isPermissionGranted()) {
//         List<Tcontact> contactList = await DatabaseHelper().getContactList();
//         for (Tcontact contact in contactList) {
//           await BackgroundSms.sendMessage(
//             phoneNumber: contact.number,
//             message: "I am in trouble, please reach me at $messageBody",
//             simSlot: 0, // Default to SIM 1
//           );
//         }
//       } else {
//         Fluttertoast.showToast(msg: "SMS permission not granted.");
//       }
//     }
//   }

//   Future<bool> _isPermissionGranted() async {
//     return await Permission.sms.isGranted;
//   }
// }
