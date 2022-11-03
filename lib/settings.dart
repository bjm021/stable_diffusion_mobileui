import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

bool hasDataLoaded = false;
var host = TextEditingController();
var steps = ValueNotifier<int>(20);
var cfg = ValueNotifier<int>(20);
var sampler = ValueNotifier("Euler");
var defaultPrompt = TextEditingController(text: "masterpiece, best quality");
var defaultNegativePrompt = TextEditingController(
    text:
        "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name");

class SettingsPage extends StatefulWidget {
  SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  var hostController = TextEditingController();
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
                    ValueListenableBuilder(
                      valueListenable: sampler,
                      builder: (context, value, child) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                    // save button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                      child: ElevatedButton(
                        // full width button
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(
                              40), // fromHeight use double.infinity as width and 40 is the height
                        ),
                        onPressed: () {
                          saveConfig(context).then(
                            (value) => Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false)
                          );
                        },
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                );
              },
            )
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

  print(
      "Saving: ${host.value}, ${steps.value}, ${cfg.value}, ${sampler.value}, ${defaultPrompt.value};;; ${defaultNegativePrompt.value}");
}

Future<void> loadSavedData() async {
  print("LOADING DATA");
  final prefs = await SharedPreferences.getInstance();
  if (!hasDataLoaded) {
    print("LOADFING ${prefs.getString("host")}");
    if (prefs.getBool("has-data") ?? false) {
      steps.value = prefs.getInt("steps") ?? 20;
      host.text = prefs.getString("host") ?? "";
      cfg.value = prefs.getInt("cfg") ?? 20;
      sampler.value = prefs.getString("sampler") ?? "Euler";
      defaultPrompt.text =
          prefs.getString("defaultPrompt") ?? "masterpiece, best quality";
      defaultNegativePrompt.text = prefs.getString("defaultNegativePrompt") ??
          "lowres, bad anatomy, bad hands, text, error, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, blurry, artist name";
      hasDataLoaded = true;
    }
  }
}
