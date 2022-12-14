import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

bool hasDataLoaded = false;

void main() {
  runApp(const MyApp());
}

bool inProgress = false;
final progressValue = ValueNotifier<double>(0.0);
double eta = 0.0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      routes: {
        '/settings': (context) => SettingsPage(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blueGrey.shade800,
        textTheme: const TextTheme(
          bodyText2: TextStyle(color: Colors.white),
          bodyText1: TextStyle(color: Colors.white),
        ),
      ),
      home: const MyHomePage(title: 'Stable Diffusion MobileUI'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

var promptController = TextEditingController();

Future<void> loadLastPrompt() async {
  var prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('last-prompt')) {
    promptController.text = prefs.getString('last-prompt')!;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  String imageDataBase64 = 'NONE';

  @override
  Widget build(BuildContext context) {
    loadLastPrompt();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
              child: TextFormField(
                controller: promptController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                  labelStyle: TextStyle(color: Colors.white),
                  labelText: 'Image prompt',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: () {
                if (imageDataBase64 == 'NONE') {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(10, 200, 10, 200),
                    child: Text(
                      'Waiting for image',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                } else {
                  return Image.memory(base64Decode(imageDataBase64));
                }
              }(),
            ),
            ValueListenableBuilder(
              valueListenable: progressValue,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: LinearProgressIndicator(
                    value: value,
                    semanticsLabel: "kkd",
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: ElevatedButton(
                onPressed: () async {
                  if (imageDataBase64 == 'NONE') {
                    return;
                  }
                  _createFileFromString(imageDataBase64).then(
                    (value) => {
                      GallerySaver.saveImage(value).then(
                        (success) => {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image saved'),
                            ),
                          ),
                          _deleteFile(value),
                        },
                      )
                    },
                  );
                },
                child: const Text('Save image'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createImage(context, promptController.text).then(
            (value) => {
              setState(() {
                var image = value;
                if (image == "ERROR") {
                  return;
                }
                if (value.contains(",")) {
                  image = value.split(",")[1];
                }
                imageDataBase64 = image;
              })
            },
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.terminal),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

Future<String> _createFileFromString(String encodedStr) async {
  Uint8List bytes = base64.decode(encodedStr);
  String dir = (await getApplicationDocumentsDirectory()).path;
  File file = File("$dir/${DateTime.now().millisecondsSinceEpoch}.png");
  await file.writeAsBytes(bytes);
  return file.path;
}

// function to delete the created image file
Future<void> _deleteFile(String path) async {
  try {
    await File(path).delete();
  } catch (e) {
    print("Failed to delete tmp image");
  }
}

class ProgressBarIndicator extends StatefulWidget {
  const ProgressBarIndicator({Key? key}) : super(key: key);

  @override
  State<ProgressBarIndicator> createState() => _ProgressBarIndicatorState();
}

class _ProgressBarIndicatorState extends State<ProgressBarIndicator>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: controller.value,
      semanticsLabel: 'Linear progress indicator',
    );
  }
}

Future<String> createImage(BuildContext context, String prompt) async {
  var map = <String, String>{};

  final prefs = await SharedPreferences.getInstance();
  prefs.setString("last-prompt", prompt);
  if (!prefs.containsKey("has-data")) {
    showDialog(
      context: context,
      builder: (context) {
        return const AlertDialog(
          title: Text("Setup Error"),
          content: Text("You have not set up the app yet!"),
        );
      },
    );
    return "ERROR";
  }

  map['prompt'] = '${prefs.getString("defaultPrompt")}, $prompt';
  map['seed'] = "-1";
  map['subseed'] = "-1";
  map['batch_size'] = "1";
  map['steps'] = "${prefs.getInt("steps")}";
  map['cfg_scale'] = "${prefs.getInt("cfg")}";
  map['width'] = "512";
  map['height'] = "512";
  map['negative_prompt'] = prefs.getString("defaultNegativePrompt")!;
  map['sampler_index'] = prefs.getString("sampler")!;

  var body = json.encode(map);

  var url = Uri(
      scheme: "http",
      host: prefs.getString("host")!.split(":")[0],
      port: int.parse(prefs.getString("host")!.split(":")[1]),
      path: "/sdapi/v1/txt2img");

  inProgress = true;
  progressValue.value = 0;
  doProgress();
  http.Response response = await http.post(url, body: body, headers: {
    "Content-Type": "application/json",
    "Accept": "application/json"
  });

  var images = jsonDecode(utf8.decode(response.bodyBytes))['images'];

  inProgress = false;
  progressValue.value = 1;
  return images[0];
}

Future<Map<String, double>> getProgress() async {
  final prefs = await SharedPreferences.getInstance();
  var url = Uri(
      scheme: "http",
      host: prefs.getString("host")!.split(":")[0],
      port: int.parse(prefs.getString("host")!.split(":")[1]),
      path: "/sdapi/v1/progress");

  http.Response response = await http.get(url);

  var jsonResp = jsonDecode(utf8.decode(response.bodyBytes));
  return {
    "progress": jsonResp['progress'],
    "eta_relative": jsonResp['eta_relative'],
  };
}

Future<void> doProgress() async {
  while (true) {
    if (!inProgress) {
      progressValue.value = 1;
      return;
    }
    getProgress().then(
      (value) => {
        progressValue.value = value['progress']!,
      },
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
