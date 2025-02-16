import 'package:fluttertoast/fluttertoast.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:women_safety/db/db_services.dart';
import 'dart:io';
import 'dart:async';
import 'package:women_safety/model/contactsm.dart';

class AudioRecorder {
  final Record _audioRecorder = Record();
  String? _filePath;
  final DatabaseHelper _databaseHelper = DatabaseHelper(); // Database Helper Instance

  // Start recording audio
  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      _filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(path: _filePath);

      // Automatically stop the recording after 10 seconds
      Timer(Duration(seconds: 10), () async {
        await stopRecording();
      });
      print("Recording started: $_filePath");
    } else {
      print("Permission not granted");
    }
  }

  // Stop recording audio
  Future<void> stopRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
      print("Recording stopped: $_filePath");

      if (_filePath != null) {
        await _uploadRecording(File(_filePath!));
      }
    }
  }

  // Fetch Trusted Contacts from Database
  Future<List<Tcontact>> _getTrustedContacts() async {
    return await _databaseHelper.getContactList();
  }

  // Upload recording to backend
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

  // Get file path
  String? get filePath => _filePath;
}
