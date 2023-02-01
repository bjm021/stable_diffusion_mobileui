import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

bool hasDataLoaded = false;
var host = TextEditingController();
var steps = ValueNotifier<int>(20);
var cfg = ValueNotifier<int>(20);
var restoreFaces = ValueNotifier<bool>(false);
var sampler = ValueNotifier("Euler");
var defaultPrompt = TextEditingController(text: "");
var defaultNegativePrompt = TextEditingController(text: "");
var width = ValueNotifier<int>(512);
var height = ValueNotifier<int>(512);

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  final hostController = TextEditingController();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    loadSavedData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "Host (e.g. 192.168.1.123:7860)",
                textAlign: TextAlign.left,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: TextFormField(
                controller: host,
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
                  labelText: 'Hostname:Port',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Divider(
                color: Colors.white,
              ),
            ),
            ValueListenableBuilder(
              valueListenable: steps,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Text(
                        "Steps: ${steps.value}",
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Slider(
                        value: value.toDouble(),
                        min: 1,
                        max: 150,
                        divisions: 149,
                        label: value.toString(),
                        onChanged: (double newValue) {
                          steps.value = newValue.round();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: cfg,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Text(
                        "CFG: ${cfg.value}",
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Slider(
                        value: value.toDouble(),
                        min: 1,
                        max: 40,
                        divisions: 39,
                        label: value.toString(),
                        onChanged: (double newValue) {
                          cfg.value = newValue.round();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: width,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Text(
                        "Image Width: ${width.value}",
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Slider(
                        value: value.toDouble(),
                        min: 256,
                        max: 2048,
                        divisions: 100,
                        label: value.toString(),
                        onChanged: (double newValue) {
                          width.value = newValue.round();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: height,
              builder: (context, value, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Text(
                        "Image Height: ${height.value}",
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Slider(
                        value: value.toDouble(),
                        min: 256,
                        max: 2048,
                        divisions: 190,
                        label: value.toString(),
                        onChanged: (double newValue) {
                          height.value = newValue.round();
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
              child: Center(
                child: ElevatedButton(
                  onPressed: () {
                    width.value = 512;
                    height.value = 512;
                  },
                  child: const Text("Reset to 512x512"),
                ),
              )
            ),
            ValueListenableBuilder(
              valueListenable: restoreFaces,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: CheckboxListTile(
                    title: const Text(
                      "Restore Faces",
                      style: TextStyle(color: Colors.white),
                    ),
                    value: value,
                    onChanged: (bool? newValue) {
                      restoreFaces.value = newValue!;
                    },
                  ),
                );
              },
            ),
            ValueListenableBuilder(
              valueListenable: sampler,
              builder: (context, value, child) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(30, 0, 30, 10),
                  child: DropdownButton(
                    onChanged: (String? newValue) {
                      sampler.value = newValue!;
                    },
                    items: const [
                      DropdownMenuItem(
                        value: "Euler a",
                        child: Text("Euler a"),
                      ),
                      DropdownMenuItem(
                        value: "Euler",
                        child: Text("Euler"),
                      ),
                      DropdownMenuItem(
                        value: "LMS",
                        child: Text("LMS"),
                      ),
                      DropdownMenuItem(
                        value: "Heun",
                        child: Text("Heun"),
                      ),
                      DropdownMenuItem(
                        value: "DPM2",
                        child: Text("DPM2"),
                      ),
                      DropdownMenuItem(
                        value: "DPM2 a",
                        child: Text("DPM2 a"),
                      ),
                      DropdownMenuItem(
                        value: "DPM++ 2S a",
                        child: Text("DPM++ 2S a"),
                      ),
                      DropdownMenuItem(
                        value: "DPM++ 2M",
                        child: Text("DPM++ 2M"),
                      ),
                      DropdownMenuItem(
                        value: "DPM++ SDE",
                        child: Text("DPM++ SDE"),
                      ),
                      DropdownMenuItem(
                        value: "DPM fast",
                        child: Text("DPM fast"),
                      ),
                      DropdownMenuItem(
                        value: "DPM adaptive",
                        child: Text("DPM adaptive"),
                      ),
                      DropdownMenuItem(
                        value: "LMS Karras",
                        child: Text("LMS Karras"),
                      ),
                      DropdownMenuItem(
                        value: "DPM2 Karras",
                        child: Text("DPM2 Karras"),
                      ),
                      DropdownMenuItem(
                        value: "DPM2 a Karras",
                        child: Text("DPM2 a Karras"),
                      ),
                      DropdownMenuItem(
                        value: "DPM++ 2S a Karras",
                        child: Text("DPM++ 2S a Karras"),
                      ),
                      DropdownMenuItem(
                        value: "DPM++ 2M Karras",
                        child: Text("DPM++ 2M Karras"),
                      ),
                      DropdownMenuItem(
                        value: "DPM++ SDE Karras",
                        child: Text("DPM++ SDE Karras"),
                      ),
                      DropdownMenuItem(
                        value: "DDIM",
                        child: Text("DDIM"),
                      ),
                      DropdownMenuItem(
                        value: "PLMS",
                        child: Text("PLMS"),
                      ),
                    ],
                    hint: const Text("Select item"),
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: Colors.blueGrey.shade900,
                    isExpanded: true,
                    value: sampler.value,
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Divider(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: TextFormField(
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
                  labelText: 'Text added to every prompt',
                ),
                controller: defaultPrompt,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: TextFormField(
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
                  labelText: 'Negative prompt',
                ),
                controller: defaultNegativePrompt,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 10, 50, 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                      40), // fromHeight use double.infinity as width and 40 is the height
                ),
                onPressed: () {
                  // modal
                  getSDModels().then(
                    (value) => {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Select SD model"),
                            backgroundColor: Colors.blueGrey.shade900,
                            contentTextStyle:
                                const TextStyle(color: Colors.white),
                            titleTextStyle:
                                const TextStyle(color: Colors.white),
                            content: Container(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: value.length,
                                itemBuilder: (context, index) {
                                  return ListTile(
                                    title: Text(value[index]["title"]),
                                    textColor: Colors.white,
                                    onTap: () {
                                      Navigator.pop(context);
                                      // display loader
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (BuildContext context) {
                                          setSDModel(
                                              value[index]["title"], context);
                                          return AlertDialog(
                                            backgroundColor:
                                                Colors.blueGrey.shade900,
                                            titleTextStyle: const TextStyle(
                                                color: Colors.white),
                                            title: const Text("Loading model"),
                                            content:
                                                const CircularProgressIndicator(),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      )
                    },
                  );
                },
                child: const Text("Change SD model"),
              ),
            ),
            // save button
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: ElevatedButton(
                // full width button
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    40,
                  ), // fromHeight use double.infinity as width and 40 is the height
                ),
                onPressed: () {
                  saveConfig(context).then(
                    (value) => Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/",
                      (route) => false,
                    ),
                  );
                },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> saveConfig(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  prefs.setBool("has-data", true);
  prefs.setString("host", host.text);
  prefs.setInt('steps', steps.value);
  prefs.setInt('cfg', cfg.value);
  prefs.setString('sampler', sampler.value);
  prefs.setString('defaultPrompt', defaultPrompt.text);
  prefs.setString('defaultNegativePrompt', defaultNegativePrompt.text);
  prefs.setBool('restore-faces', restoreFaces.value);
  prefs.setInt("width", width.value);
  prefs.setInt("height", height.value);

  print(
      "Saving: ${host.value}, ${steps.value}, ${cfg.value}, ${sampler.value}, ${defaultPrompt.value};;; ${defaultNegativePrompt.value}");
}

Future<void> loadSavedData() async {
  final prefs = await SharedPreferences.getInstance();
  if (!hasDataLoaded) {
    if (prefs.getBool("has-data") ?? false) {
      steps.value = prefs.getInt("steps") ?? 20;
      host.text = prefs.getString("host") ?? "";
      cfg.value = prefs.getInt("cfg") ?? 20;
      restoreFaces.value = prefs.getBool("restore-faces") ?? false;
      sampler.value = prefs.getString("sampler") ?? "Euler";
      defaultPrompt.text = prefs.getString("defaultPrompt") ?? "";
      defaultNegativePrompt.text =
          prefs.getString("defaultNegativePrompt") ?? "";
      width.value = prefs.getInt("width") ?? 512;
      height.value = prefs.getInt("height") ?? 512;
      hasDataLoaded = true;
    }
  }
}

// modal widget
Widget buildSelectModal(stringList, context) {
  return Center();
}

Future<List<dynamic>> getSDModels() async {
  final prefs = await SharedPreferences.getInstance();
  var url = Uri(
      scheme: "http",
      host: prefs.getString("host")!.split(":")[0],
      port: int.parse(prefs.getString("host")!.split(":")[1]),
      path: "/sdapi/v1/sd-models");

  http.Response response = await http.get(url);

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    print(data);
    return data;
  } else {
    throw Exception('Failed to load models');
  }
}

Future<void> setSDModel(model, context) async {
  print("Setting model to $model");
  print("--------------------------------------------------");

  final prefs = await SharedPreferences.getInstance();

  var url = Uri(
      scheme: "http",
      host: prefs.getString("host")!.split(":")[0],
      port: int.parse(prefs.getString("host")!.split(":")[1]),
      path: "/sdapi/v1/options");

  var map = <String, String>{};
  map["sd_model_checkpoint"] = model;
  var body = json.encode(map);
  http.Response response = await http.post(url, body: body, headers: {
    "Content-Type": "application/json",
    "Accept": "application/json"
  });

  if (response.statusCode == 200) {
    print("Model set to $model");
    Navigator.pop(context);
  } else {
    // print response
    print(response.body);
    throw Exception('Failed to set model! Status code: ${response.statusCode}');
  }
}
