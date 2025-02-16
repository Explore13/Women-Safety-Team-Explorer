// import 'dart:async';
// import 'dart:ui';

// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:women_safety/utils/voice_recog_bg.dart';

// Future<void> initializeService() async {
//   final service = FlutterBackgroundService();

//   AndroidNotificationChannel channel = AndroidNotificationChannel(
//     "script_academy",
//     "Foreground Service",
//     description: "This notification keeps the background service active.",
//     importance: Importance.high,
//   );

//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   await flutterLocalNotificationsPlugin
//       .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//       ?.createNotificationChannel(channel);

//   await service.configure(
//     iosConfiguration: IosConfiguration(),
//     androidConfiguration: AndroidConfiguration(
//       onStart: onStart,
//       isForegroundMode: true,
//       autoStart: true,
//       notificationChannelId: "script_academy",
//       initialNotificationTitle: "Women Safety App",
//       initialNotificationContent: "Voice detection is active",
//       foregroundServiceNotificationId: 888,
//     ),
//   );

//   service.startService();
// }

// @pragma('vm-entry-point')
// void onStart(ServiceInstance service) {
//   DartPluginRegistrant.ensureInitialized();
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Create the persistent notification only once.
//   if (service is AndroidServiceInstance) {
//     service.setForegroundNotificationInfo(
//       title: "Women Safety App",
//       content: "Voice detection is active",
//     );
//   }

//   service.on('stopService').listen((event) {
//     service.stopSelf();
//   });

//   Timer.periodic(Duration(seconds: 2), (timer) async {
//     if (service is AndroidServiceInstance) {
//       if (!(await service.isForegroundService())) {
//         service.setForegroundNotificationInfo(
//           title: "Women Safety App",
//           content: "Voice detection is active",
//         );
//       }
//     }
//   });
// }

// // VoiceRecognitionService().startListening();


import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:women_safety/db/db_services.dart';
import 'package:women_safety/model/contactsm.dart';
import 'package:background_sms/background_sms.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  AndroidNotificationChannel channel = AndroidNotificationChannel(
    "script_academy",
    "Foreground Service",
    description: "Keeps the background service running.",
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    iosConfiguration: IosConfiguration(),
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: "script_academy",
      initialNotificationTitle: "Women Safety App",
      initialNotificationContent: "Voice detection is active",
      foregroundServiceNotificationId: 888,
    ),
  );

  service.startService();
}

@pragma('vm-entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final AudioRecorder _audioRecorder = AudioRecorder();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Women Safety App",
      content: "Voice detection is active",
    );
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  void startListening() async {
    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          startListening(); // Restart listening
        }
      },
      onError: (error) {
        startListening(); // Restart in case of error
      },
    );

    if (available) {
      _speech.listen(onResult: (val) async {
        if (val.recognizedWords.toLowerCase().contains('me to')) {
          await _sendLocationToContacts();
          await _audioRecorder.startRecording();
          _showToast("Location sent, recording started.");
        }
      });
    }
  }

  startListening();

  Timer.periodic(Duration(seconds: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) {
        service.setForegroundNotificationInfo(
          title: "Women Safety App",
          content: "Voice detection is active",
        );
      }
    }
  });
}

// 📌 Send Location to Emergency Contacts
Future<void> _sendLocationToContacts() async {
  if (!(await Permission.sms.isGranted)) {
    Fluttertoast.showToast(msg: "SMS permission not granted.");
    return;
  }

  Position? position;
  try {
    position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  } catch (e) {
    Fluttertoast.showToast(msg: "Failed to get location: $e");
    return;
  }

  String messageBody =
      "https://www.google.com/maps/search/?api=1&query=${position.latitude}%2C${position.longitude}";

  List<Tcontact> contactList = await DatabaseHelper().getContactList();
  for (Tcontact contact in contactList) {
    var result = await BackgroundSms.sendMessage(
      phoneNumber: contact.number,
      message: "I am in trouble, please reach me at $messageBody",
      simSlot: 1,
    );

    if (result == SmsStatus.sent) {
      Fluttertoast.showToast(msg: "Message sent to ${contact.name}");
    } else {
      Fluttertoast.showToast(msg: "Failed to send message");
    }
  }
}

// 📌 Show Toast Notification
void _showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

// 📌 Audio Recorder Class
class AudioRecorder {
  final Record _audioRecorder = Record();
  String? _filePath;
  final DatabaseHelper _databaseHelper = DatabaseHelper(); // Database Helper Instance

  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(path: _filePath);

      print("✅ Recording started: $_filePath");

      // Stop recording after 10 seconds
      Future.delayed(Duration(seconds: 10), () async {
        await stopRecording();
      });
    } else {
      print("❌ Permission not granted");
    }
  }

  Future<void> stopRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
      print("✅ Recording stopped: $_filePath");

      if (_filePath != null) {
        await _uploadRecording(File(_filePath!));
      }
    }
  }

  // 📌 Fetch Trusted Contacts from Database
  Future<List<Tcontact>> _getTrustedContacts() async {
    return await _databaseHelper.getContactList();
  }

  // 📌 Upload Audio Recording to Backend
  Future<void> _uploadRecording(File file) async {
    var uri = Uri.parse("https://1ps7m2k2-5000.inc1.devtunnels.ms/predict");

    // Fetch trusted contacts
    List<Tcontact> contacts = await _getTrustedContacts();
    List<String> contactNumbers = contacts.map((c) => c.number).toList();

    var request = http.MultipartRequest("POST", uri)
      ..files.add(await http.MultipartFile.fromPath('file', file.path))
      ..fields['trustedContacts'] = contactNumbers.join(",");

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "File uploaded successfully");
        print("✅ Server Response: $responseBody");
      } else {
        Fluttertoast.showToast(msg: "File upload failed");
        print("❌ Error: ${response.reasonPhrase}");
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error uploading file");
      print("❌ Exception: $e");
    }
  }

  String? get filePath => _filePath;
}
