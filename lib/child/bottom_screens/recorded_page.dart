import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:women_safety/db/db_services.dart';
import 'package:women_safety/model/contactsm.dart';

class RecordedFilesPage extends StatefulWidget {
  const RecordedFilesPage({super.key});

  @override
  State<RecordedFilesPage> createState() => _RecordedFilesPageState();
}

class _RecordedFilesPageState extends State<RecordedFilesPage> {
  List<FileSystemEntity>? recordedFiles = [];
  late AudioPlayer _audioPlayer;
  DatabaseHelper _databaseHelper = DatabaseHelper(); // Database Helper Instance
  int fileCount = 0;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecordedFiles();
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  // Load recorded files from the app's directory
  Future<void> _loadRecordedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().where((file) => file.path.endsWith('.m4a')).toList();
    setState(() {
      recordedFiles = files;
      fileCount = files.length;
    });
    print("Loaded ${files.length} recorded files");
  }

  // Play the selected recording
  Future<void> _playRecording(String path) async {
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(path));
  }

  // Delete a recording
  Future<void> _deleteRecording(FileSystemEntity file) async {
    try {
      await file.delete();
      Fluttertoast.showToast(msg: "Recording deleted successfully");
      _loadRecordedFiles();
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to delete recording");
    }
  }

  // Fetch Trusted Contacts from Database
  Future<List<Tcontact>> _getTrustedContacts() async {
    return await _databaseHelper.getContactList();
  }

  // Upload recording with trusted contacts
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recorded Files'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(12),
          child: recordedFiles!.isEmpty
              ? Center(child: Text("No recordings found"))
              : ListView.builder(
                  itemCount: fileCount,
                  itemBuilder: (BuildContext context, int index) {
                    final file = recordedFiles![index];
                    final fileName = file.path.split('/').last;

                    return Card(
                      child: ListTile(
                        title: Text(fileName),
                        trailing: Container(
                          width: 150,
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => _playRecording(file.path),
                                icon: Icon(Icons.play_arrow),
                                color: Colors.blue,
                              ),
                              IconButton(
                                onPressed: () => _deleteRecording(file),
                                icon: Icon(Icons.delete),
                                color: Colors.red,
                              ),
                              IconButton(
                                onPressed: () => _uploadRecording(File(file.path)),
                                icon: Icon(Icons.cloud_upload),
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}