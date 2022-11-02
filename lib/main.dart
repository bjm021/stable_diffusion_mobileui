import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

class _MyHomePageState extends State<MyHomePage> {
  String imageDataBase64 = 'NONE';
  var promptController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                        'Waiting for 1st image',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  } else {
                    return Image.memory(base64Decode(imageDataBase64));
                  }
                }()),
            ValueListenableBuilder(
              valueListenable: progressValue,
              builder: (context, value, child) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: LinearProgressIndicator(
                    value: value,
                    semanticsLabel: "kkd",
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createImage(promptController.text).then((value) => {
                setState(() {
                  var image = value;
                  if (value.contains(",")) {
                    image = value.split(",")[1];
                  }
                  imageDataBase64 = image;
                })
              });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.start),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
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

Future<String> createImage(String prompt) async {
  var map = <String, String>{};

  print("Starting request");

  map['enable_hr'] = "false";
  map['denoising_strength'] = "0";
  map['prompt'] = 'masterpiece, best quality, masterpiece, $prompt';
  map['seed'] = "-1";
  map['subseed'] = "-1";
  map['batch_size'] = "1";
  map['steps'] = "20";
  map['cfg_scale'] = "20";
  map['width'] = "512";
  map['height'] = "512";
  map['negative_prompt'] =
      "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name";
  map['sampler_index'] = "Euler";

  var body = json.encode(map);

  var url = Uri(
      scheme: "http",
      host: "192.168.7.148",
      port: 7860,
      path: "/sdapi/v1/txt2img");

  inProgress = true;
  progressValue.value = 0;
  doProgress();
  http.Response response = await http
      .post(url, body: body, headers: {"Content-Type": "application/json"});

  var images = jsonDecode(utf8.decode(response.bodyBytes))['images'];

  inProgress = false;
  progressValue.value = 1;
  return images[0];
}

Future<Map<String, double>> getProgress() async {
  var url = Uri(
      scheme: "http",
      host: "192.168.7.148",
      port: 7860,
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
    await Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!inProgress) {
          progressValue.value = 1;
          return;
        }
        getProgress().then(
          (value) => {
            progressValue.value = value['progress']!,
            print("Setting ${(value['progress']! / value['eta_relative']!)} from ${value['progress']} / ${value['eta_relative']}")
          },
        );
      },
    );
  }
}
