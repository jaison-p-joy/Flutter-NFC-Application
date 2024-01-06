import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter NFC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter NFC'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  static const platform = MethodChannel('com.example.nfc_project/nfc');

  final TextEditingController _textController = TextEditingController();

  String _nfcStatusMessage = '';
  String _tagId = 'Not Scanned';
  String _storage = 'Not Scanned';
  String _writableStatus = 'Not Scanned';
  String _message = 'Not Scanned';

  Color _nfcStatusColor = Colors.black;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Future<void> _readNfcTag() async {
  //   try {
  //     final result = await platform.invokeMethod('getNfcDetails');
  //     setState(() {
  //       _tagId = result['tagId'];
  //       _storage = result['storage'];
  //       _writableStatus = result['writable'] ? 'Yes' : 'No';
  //       _message = result['message'] ?? 'NO MESSAGE';
  //     });
  //   } on PlatformException catch (e) {
  //     // Handle exception by showing an error message
  //   }
  // }

  @override
  void initState() {
    super.initState();
    _checkInitialNfcStatus();

    var initializationSettingsAndroid =
    const AndroidInitializationSettings('baseline_nfc_24');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    platform.setMethodCallHandler(_handleMethodCall);
  }


  Future<dynamic> _handleMethodCall(MethodCall call) async {
      if (call.method == "updateNfcStatus") {
    _updateNfcStatus(call.arguments);
    } else if (call.method == "onNfcTagDiscovered") {
    _updateTagDetails(call.arguments);
    _showNotification(call.arguments);
    }

  }

  Future<void> _checkInitialNfcStatus() async {
    try {
      final result = await platform.invokeMethod('checkNfc');
      _updateNfcStatus(result);
    } catch (e) {
      // Handle any errors here
    }
  }

  void _updateNfcStatus(dynamic status) {
    setState(() {
      if (status['isSupported'] == false) {
        _nfcStatusMessage = 'NFC is not supported on this device.';
        _nfcStatusColor = Colors.red;
      } else if (status['isEnabled'] == false) {
        _nfcStatusMessage = 'NFC is not enabled. Please enable it in the settings.';
        _nfcStatusColor = Colors.orange;
      } else {
        _nfcStatusMessage = 'NFC is enabled.';
        _nfcStatusColor = Colors.green;
      }
    });
  }

  void _updateTagDetails(dynamic details) {
    setState(() {
      _tagId = details['tagId'];
      _storage = details['storage'];
      _writableStatus = details['writable'] ? 'Yes' : 'No';
      _message = details['message'];
    });
  }

  Future<void> _writeNfcTag(String message) async {
    try {
      final bool result = await platform.invokeMethod('writeNfcTag', {'message': message});
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tag written successfully"),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to write tag"),
        ));
      }
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error writing NFC tag: '${e.message}'."),
      ));
    }
  }



 Future <void> _showNotification(dynamic details) async {
   String tagId = details['tagId'];
   String message = details['message'];
    if (message.isNotEmpty) {
      var androidDetails = const AndroidNotificationDetails(
        'nfc_scan_channel',
        'NFC Scan',
        channelDescription: 'Notification when NFC tag is scanned',
        importance: Importance.max,
        priority: Priority.high,
      );
      var generalNotificationDetails =
      NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        0, // Notification ID
        'NFC Tag Scanned', // Notification Title
        'Tag ID: $tagId, Message: $message', // Notification Body
        generalNotificationDetails,
      );
    }
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Flutter NFC Method Channel - Android"),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("NFC Tag Details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(
                    height: 10.0,
                    width: 0.0,
                  ),
                  Text(
                    _nfcStatusMessage,
                    style: TextStyle(
                      fontSize: 16,
                      color: _nfcStatusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                    width: 0.0,
                  ),
                  const Text("Tag Id",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(
                    height: 5.0,
                    width: 0.0,
                  ),
                  Container(
                    width: double.infinity,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_tagId,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400
                            ),),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18.0,
                    width: 0.0,
                  ),
                  const Text("Storage",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(
                    height: 5.0,
                    width: 0.0,
                  ),
                  Container(
                    width: double.infinity,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("$_storage bytes",
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400
                            ),),
                        ],
                      ),
                    ),
                  ), const SizedBox(
                    height: 18.0,
                    width: 0.0,
                  ),
                  const Text("Writable Status",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(
                    height: 5.0,
                    width: 0.0,
                  ),
                  Container(
                    width: double.infinity,
                    height: 64.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_writableStatus,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400
                            ),),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18.0,
                    width: 0.0,
                  ),
                  const Text("Message",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(
                    height: 5.0,
                    width: 0.0,
                  ),
                  Container(
                    width: double.infinity,
                    height: 128.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(_message,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400
                            ),),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                    width: 0.0,
                  ),
                  Divider(
                    color: Colors.grey[300],
                    thickness: 1.5,
                  ),
                  const SizedBox(
                    height: 10.0,
                    width: 0.0,
                  ),
                  const Text(" Write to NFC Tag",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                  const SizedBox(
                    height: 5.0,
                    width: 0.0,
                  ),
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            10.0), // Circular edges
                      ),
                      hintText: 'Enter text here',
                    ),
                  ),
                  const SizedBox(
                    height: 20.0,
                    width: 0.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _writeNfcTag(_textController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          fixedSize: const Size.fromHeight(48.0),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)
                          ),
                        ),
                        child: const Text('Write Tag',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  )
                ],
              ),),
          ),
        ),
      );
    }
}
