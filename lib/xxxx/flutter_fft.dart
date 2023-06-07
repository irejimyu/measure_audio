import 'package:flutter/material.dart';
import 'package:flutter_fft/flutter_fft.dart';

class Application extends StatefulWidget {
  const Application({Key? key}) : super(key: key);

  @override
  ApplicationState createState() => ApplicationState();
}

class ApplicationState extends State<Application> {
  double frequency = 0;
  int octave = 0;

  FlutterFft flutterFft = FlutterFft();

  _initialize() async {
    while (!(await flutterFft.checkPermission())) {
      flutterFft.requestPermission();
    }

    await flutterFft.startRecorder();
    flutterFft.onRecorderStateChanged.listen(
      (data) {
        print("Changed state, received: $data");
        if (data.isNotEmpty && data[5] == 5) {
          frequency = data[1] as double;
          octave = data[5] as int;
          flutterFft.setFrequency = frequency;
          flutterFft.setOctave = octave;
          print("Octave: ${octave.toString()}");
        } else {
          frequency = 0;
        }

        if (mounted) setState(() {});
      },
      onError: (err) {
        print("Error: $err");
      },
    );
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    flutterFft.stopRecorder();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter_FFT'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            flutterFft.getIsRecording
                ? Text(
                    "Current frequency: ${frequency.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 30),
                  )
                : const Text(
                    "Not Recording",
                    style: TextStyle(fontSize: 35),
                  )
          ],
        ),
      ),
    );
  }
}
